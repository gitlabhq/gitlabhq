import { nextTick } from 'vue';
import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/flash';
import GroupSelect from '~/vue_shared/components/group_select/group_select.vue';
import {
  TOGGLE_TEXT,
  FETCH_GROUPS_ERROR,
  FETCH_GROUP_ERROR,
  QUERY_TOO_SHORT_MESSAGE,
} from '~/vue_shared/components/group_select/constants';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/flash');

describe('GroupSelect', () => {
  let wrapper;
  let mock;

  // Mocks
  const groupMock = {
    full_name: 'selectedGroup',
    id: '1',
  };
  const groupEndpoint = `/api/undefined/groups/${groupMock.id}`;

  // Props
  const inputName = 'inputName';
  const inputId = 'inputId';

  // Finders
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInput = () => wrapper.findByTestId('input');

  // Helpers
  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupSelect, {
      propsData: {
        inputName,
        inputId,
        ...props,
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
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: FETCH_GROUP_ERROR,
          error: expect.any(Error),
          parent: wrapper.vm.$el,
        });
      });
    });
  });

  it('shows an error when fetching groups fails', async () => {
    mock.onGet('/api/undefined/groups.json').reply(500);
    createComponent();
    openListbox();
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: FETCH_GROUPS_ERROR,
      error: expect.any(Error),
      parent: wrapper.vm.$el,
    });
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
      expect(mock.history.get[1].params).toStrictEqual({ search: searchString });
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
});
