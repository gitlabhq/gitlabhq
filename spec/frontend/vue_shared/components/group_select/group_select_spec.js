import { nextTick } from 'vue';
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import GroupSelect from '~/vue_shared/components/group_select/group_select.vue';
import {
  TOGGLE_TEXT,
  RESET_LABEL,
  FETCH_GROUPS_ERROR,
  FETCH_GROUP_ERROR,
  QUERY_TOO_SHORT_MESSAGE,
} from '~/vue_shared/components/group_select/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('GroupSelect', () => {
  let wrapper;
  let mock;

  // Mocks
  const groupMock = {
    full_name: 'selectedGroup',
    id: '1',
  };
  const groupEndpoint = `/api/undefined/groups/${groupMock.id}`;

  // Stubs
  const GlAlert = {
    template: '<div><slot /></div>',
  };

  // Props
  const label = 'label';
  const inputName = 'inputName';
  const inputId = 'inputId';

  // Finders
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInput = () => wrapper.findByTestId('input');
  const findAlert = () => wrapper.findComponent(GlAlert);

  // Helpers
  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupSelect, {
      propsData: {
        label,
        inputName,
        inputId,
        ...props,
      },
      stubs: {
        GlAlert,
      },
    });
  };
  const openListbox = () => findListbox().vm.$emit('shown');
  const search = (searchString) => findListbox().vm.$emit('search', searchString);
  const createComponentWithGroups = () => {
    mock.onGet('/api/undefined/groups.json').reply(200, [groupMock]);
    createComponent();
    openListbox();
    return waitForPromises();
  };
  const selectGroup = () => {
    findListbox().vm.$emit('select', groupMock.id);
    return nextTick();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('passes the label to GlFormGroup', () => {
    createComponent();

    expect(findFormGroup().attributes('label')).toBe(label);
  });

  describe('on mount', () => {
    it('fetches groups when the listbox is opened', async () => {
      createComponent();
      await waitForPromises();

      expect(mock.history.get).toHaveLength(0);

      openListbox();
      await waitForPromises();

      expect(mock.history.get).toHaveLength(1);
    });

    describe('with an initial selection', () => {
      it('if the selected group is not part of the fetched list, fetches it individually', async () => {
        mock.onGet(groupEndpoint).reply(200, groupMock);
        createComponent({ props: { initialSelection: groupMock.id } });
        await waitForPromises();

        expect(mock.history.get).toHaveLength(1);
        expect(findListbox().props('toggleText')).toBe(groupMock.full_name);
      });

      it('show an error if fetching the individual group fails', async () => {
        mock
          .onGet('/api/undefined/groups.json')
          .reply(200, [{ full_name: 'notTheSelectedGroup', id: '2' }]);
        mock.onGet(groupEndpoint).reply(500);
        createComponent({ props: { initialSelection: groupMock.id } });

        expect(findAlert().exists()).toBe(false);

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(FETCH_GROUP_ERROR);
      });
    });
  });

  it('shows an error when fetching groups fails', async () => {
    mock.onGet('/api/undefined/groups.json').reply(500);
    createComponent();
    openListbox();
    expect(findAlert().exists()).toBe(false);

    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe(FETCH_GROUPS_ERROR);
  });

  describe('selection', () => {
    it('uses the default toggle text while no group is selected', async () => {
      await createComponentWithGroups();

      expect(findListbox().props('toggleText')).toBe(TOGGLE_TEXT);
    });

    describe('once a group is selected', () => {
      it(`uses the selected group's name as the toggle text`, async () => {
        await createComponentWithGroups();
        await selectGroup();

        expect(findListbox().props('toggleText')).toBe(groupMock.full_name);
      });

      it(`uses the selected group's ID as the listbox' and input value`, async () => {
        await createComponentWithGroups();
        await selectGroup();

        expect(findListbox().attributes('selected')).toBe(groupMock.id);
        expect(findInput().attributes('value')).toBe(groupMock.id);
      });

      it(`on reset, falls back to the default toggle text`, async () => {
        await createComponentWithGroups();
        await selectGroup();

        findListbox().vm.$emit('reset');
        await nextTick();

        expect(findListbox().props('toggleText')).toBe(TOGGLE_TEXT);
      });
    });
  });

  describe('search', () => {
    it('sets `searching` to `true` when first opening the dropdown', async () => {
      createComponent();

      expect(findListbox().props('searching')).toBe(false);

      openListbox();
      await nextTick();

      expect(findListbox().props('searching')).toBe(true);
    });

    it('sets `searching` to `true` while searching', async () => {
      await createComponentWithGroups();

      expect(findListbox().props('searching')).toBe(false);

      search('foo');
      await nextTick();

      expect(findListbox().props('searching')).toBe(true);
    });

    it('fetches groups matching the search string', async () => {
      const searchString = 'searchString';
      await createComponentWithGroups();

      expect(mock.history.get).toHaveLength(1);

      search(searchString);
      await waitForPromises();

      expect(mock.history.get).toHaveLength(2);
      expect(mock.history.get[1].params).toStrictEqual({
        page: 1,
        per_page: 20,
        search: searchString,
      });
    });

    it('shows a notice if the search query is too short', async () => {
      const searchString = 'a';
      await createComponentWithGroups();
      search(searchString);
      await waitForPromises();

      expect(mock.history.get).toHaveLength(1);
      expect(findListbox().props('noResultsText')).toBe(QUERY_TOO_SHORT_MESSAGE);
    });
  });

  describe('pagination', () => {
    const searchString = 'searchString';

    beforeEach(async () => {
      let requestCount = 0;
      mock.onGet('/api/undefined/groups.json').reply(({ params }) => {
        requestCount += 1;
        return [
          200,
          [
            {
              full_name: `Group [page: ${params.page} - search: ${params.search}]`,
              id: requestCount,
            },
          ],
          {
            page: params.page,
            'x-total-pages': 3,
          },
        ];
      });
      createComponent();
      openListbox();
      findListbox().vm.$emit('bottom-reached');
      return waitForPromises();
    });

    it('fetches the next page when bottom is reached', async () => {
      expect(mock.history.get).toHaveLength(2);
      expect(mock.history.get[1].params).toStrictEqual({
        page: 2,
        per_page: 20,
        search: '',
      });
    });

    it('fetches the first page when the search query changes', async () => {
      search(searchString);
      await waitForPromises();

      expect(mock.history.get).toHaveLength(3);
      expect(mock.history.get[2].params).toStrictEqual({
        page: 1,
        per_page: 20,
        search: searchString,
      });
    });

    it('retains the search query when infinite scrolling', async () => {
      search(searchString);
      await waitForPromises();
      findListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(mock.history.get).toHaveLength(4);
      expect(mock.history.get[3].params).toStrictEqual({
        page: 2,
        per_page: 20,
        search: searchString,
      });
    });

    it('pauses infinite scroll after fetching the last page', async () => {
      expect(findListbox().props('infiniteScroll')).toBe(true);

      findListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(findListbox().props('infiniteScroll')).toBe(false);
    });

    it('resumes infinite scroll when search query changes', async () => {
      findListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(findListbox().props('infiniteScroll')).toBe(false);

      search(searchString);
      await waitForPromises();

      expect(findListbox().props('infiniteScroll')).toBe(true);
    });
  });

  it.each`
    description        | clearable | expectedLabel
    ${'passes'}        | ${true}   | ${RESET_LABEL}
    ${'does not pass'} | ${false}  | ${''}
  `(
    '$description the reset button label to the listbox when clearable is $clearable',
    ({ clearable, expectedLabel }) => {
      createComponent({
        props: {
          clearable,
        },
      });

      expect(findListbox().props('resetButtonLabel')).toBe(expectedLabel);
    },
  );
});
