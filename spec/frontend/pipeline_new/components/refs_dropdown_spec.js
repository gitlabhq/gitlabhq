import { GlListbox, GlListboxItem } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

import RefsDropdown from '~/pipeline_new/components/refs_dropdown.vue';

import { mockBranches, mockRefs, mockFilteredRefs, mockTags } from '../mock_data';

const projectRefsEndpoint = '/root/project/refs';
const refShortName = 'main';
const refFullName = 'refs/heads/main';

jest.mock('~/flash');

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;

  const findDropdown = () => wrapper.findComponent(GlListbox);
  const findRefsDropdownItems = () => wrapper.findAllComponents(GlListboxItem);
  const findSearchBox = () => wrapper.findByTestId('listbox-search-input');
  const findListboxGroups = () => wrapper.findAll('ul[role="group"]');

  const createComponent = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(RefsDropdown, {
      provide: {
        projectRefsEndpoint,
      },
      propsData: {
        value: {
          shortName: refShortName,
          fullName: refFullName,
        },
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(projectRefsEndpoint, { params: { search: '' } }).reply(HTTP_STATUS_OK, mockRefs);
  });

  beforeEach(() => {
    createComponent();
  });

  it('displays empty dropdown initially', () => {
    findDropdown().vm.$emit('shown');

    expect(findRefsDropdownItems()).toHaveLength(0);
  });

  it('does not make requests immediately', async () => {
    expect(mock.history.get).toHaveLength(0);
  });

  describe('when user opens dropdown', () => {
    beforeEach(async () => {
      createComponent({}, mountExtended);
      findDropdown().vm.$emit('shown');
      await waitForPromises();
    });

    it('requests unfiltered tags and branches', () => {
      expect(mock.history.get).toHaveLength(1);
      expect(mock.history.get[0].url).toBe(projectRefsEndpoint);
      expect(mock.history.get[0].params).toEqual({ search: '' });
    });

    it('displays dropdown with branches and tags', () => {
      const refLength = mockRefs.Tags.length + mockRefs.Branches.length;
      expect(findRefsDropdownItems()).toHaveLength(refLength);
    });

    it('displays the names of refs', () => {
      // Branches
      expect(findRefsDropdownItems().at(0).text()).toBe(mockRefs.Branches[0]);

      // Tags (appear after branches)
      const firstTag = mockRefs.Branches.length;
      expect(findRefsDropdownItems().at(firstTag).text()).toBe(mockRefs.Tags[0]);
    });

    it('when user shows dropdown a second time, only one request is done', () => {
      expect(mock.history.get).toHaveLength(1);
    });

    describe('when user selects a value', () => {
      const selectedIndex = 1;

      beforeEach(async () => {
        findRefsDropdownItems().at(selectedIndex).vm.$emit('select', 'refs/heads/branch-1');
        await waitForPromises();
      });

      it('component emits @input', () => {
        const inputs = wrapper.emitted('input');

        expect(inputs).toHaveLength(1);
        expect(inputs[0]).toEqual([{ shortName: 'branch-1', fullName: 'refs/heads/branch-1' }]);
      });
    });

    describe('when user types searches for a tag', () => {
      const mockSearchTerm = 'my-search';

      beforeEach(async () => {
        mock
          .onGet(projectRefsEndpoint, { params: { search: mockSearchTerm } })
          .reply(HTTP_STATUS_OK, mockFilteredRefs);

        await findSearchBox().vm.$emit('input', mockSearchTerm);
        await waitForPromises();
      });

      it('requests filtered tags and branches', async () => {
        expect(mock.history.get).toHaveLength(2);
        expect(mock.history.get[1].params).toEqual({
          search: mockSearchTerm,
        });
      });

      it('displays dropdown with branches and tags', async () => {
        const filteredRefLength = mockFilteredRefs.Tags.length + mockFilteredRefs.Branches.length;

        expect(findRefsDropdownItems()).toHaveLength(filteredRefLength);
      });
    });
  });

  describe('when user has selected a value', () => {
    const selectedIndex = 1;
    const mockShortName = mockRefs.Branches[selectedIndex];
    const mockFullName = `refs/heads/${mockShortName}`;

    beforeEach(async () => {
      mock
        .onGet(projectRefsEndpoint, {
          params: { ref: mockFullName },
        })
        .reply(HTTP_STATUS_OK, mockRefs);

      createComponent(
        {
          value: {
            shortName: mockShortName,
            fullName: mockFullName,
          },
        },
        mountExtended,
      );
      findDropdown().vm.$emit('shown');
      await waitForPromises();
    });

    it('branch is checked', () => {
      expect(findRefsDropdownItems().at(selectedIndex).props('isSelected')).toBe(true);
    });
  });

  describe('when server returns an error', () => {
    beforeEach(async () => {
      mock
        .onGet(projectRefsEndpoint, { params: { search: '' } })
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      findDropdown().vm.$emit('shown');
      await waitForPromises();
    });

    it('loading error event is emitted', () => {
      expect(wrapper.emitted('loadingError')).toHaveLength(1);
      expect(wrapper.emitted('loadingError')[0]).toEqual([expect.any(Error)]);
    });
  });

  describe('should display branches and tags based on its length', () => {
    it.each`
      mockData                                    | expectedGroupLength | expectedListboxItemsLength
      ${{ ...mockBranches, Tags: [] }}            | ${1}                | ${mockBranches.Branches.length}
      ${{ Branches: [], ...mockTags }}            | ${1}                | ${mockTags.Tags.length}
      ${{ ...mockRefs }}                          | ${2}                | ${mockBranches.Branches.length + mockTags.Tags.length}
      ${{ Branches: undefined, Tags: undefined }} | ${0}                | ${0}
    `(
      'should render branches and tags based on presence',
      async ({ mockData, expectedGroupLength, expectedListboxItemsLength }) => {
        mock.onGet(projectRefsEndpoint, { params: { search: '' } }).reply(HTTP_STATUS_OK, mockData);
        createComponent({}, mountExtended);
        findDropdown().vm.$emit('shown');
        await waitForPromises();

        expect(findListboxGroups()).toHaveLength(expectedGroupLength);
        expect(findRefsDropdownItems()).toHaveLength(expectedListboxItemsLength);
      },
    );
  });
});
