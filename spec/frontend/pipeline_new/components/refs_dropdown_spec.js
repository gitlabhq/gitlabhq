import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

import RefsDropdown from '~/pipeline_new/components/refs_dropdown.vue';

import { mockRefs, mockFilteredRefs } from '../mock_data';

const projectRefsEndpoint = '/root/project/refs';
const refShortName = 'main';
const refFullName = 'refs/heads/main';

jest.mock('~/flash');

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;

  const findDropdown = () => wrapper.find(GlDropdown);
  const findRefsDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  const createComponent = (props = {}, mountFn = shallowMount) => {
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
    mock.onGet(projectRefsEndpoint, { params: { search: '' } }).reply(httpStatusCodes.OK, mockRefs);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  beforeEach(() => {
    createComponent();
  });

  it('displays empty dropdown initially', async () => {
    await findDropdown().vm.$emit('show');

    expect(findRefsDropdownItems()).toHaveLength(0);
  });

  it('does not make requests immediately', async () => {
    expect(mock.history.get).toHaveLength(0);
  });

  describe('when user opens dropdown', () => {
    beforeEach(async () => {
      await findDropdown().vm.$emit('show');
      await waitForPromises();
    });

    it('requests unfiltered tags and branches', async () => {
      expect(mock.history.get).toHaveLength(1);
      expect(mock.history.get[0].url).toBe(projectRefsEndpoint);
      expect(mock.history.get[0].params).toEqual({ search: '' });
    });

    it('displays dropdown with branches and tags', async () => {
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
        await findRefsDropdownItems().at(selectedIndex).vm.$emit('click');
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
          .reply(httpStatusCodes.OK, mockFilteredRefs);

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
        .reply(httpStatusCodes.OK, mockRefs);

      createComponent({
        value: {
          shortName: mockShortName,
          fullName: mockFullName,
        },
      });
      await findDropdown().vm.$emit('show');
      await waitForPromises();
    });

    it('branch is checked', () => {
      expect(findRefsDropdownItems().at(selectedIndex).props('isChecked')).toBe(true);
    });
  });

  describe('when server returns an error', () => {
    beforeEach(async () => {
      mock
        .onGet(projectRefsEndpoint, { params: { search: '' } })
        .reply(httpStatusCodes.INTERNAL_SERVER_ERROR);

      await findDropdown().vm.$emit('show');
      await waitForPromises();
    });

    it('loading error event is emitted', () => {
      expect(wrapper.emitted('loadingError')).toHaveLength(1);
      expect(wrapper.emitted('loadingError')[0]).toEqual([expect.any(Error)]);
    });
  });
});
