import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewEnvironmentsDropdown from '~/feature_flags/components/new_environments_dropdown.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_HOST = '/test';
const TEST_SEARCH = 'production';

describe('New Environments Dropdown', () => {
  let wrapper;
  let axiosMock;

  const createWrapper = (axiosResult = []) => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, axiosResult);

    wrapper = shallowMountExtended(NewEnvironmentsDropdown, {
      provide: { environmentsEndpoint: TEST_HOST },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findCreateEnvironmentButton = () => wrapper.findByTestId('add-environment-button');

  afterEach(() => {
    axiosMock.restore();
  });

  describe('before results', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should show a loading icon', () => {
      expect(findListbox().props('searching')).toBe(true);
    });

    it('should not show any dropdown items', () => {
      expect(findListbox().props('items')).toEqual([]);
    });
  });

  describe('with empty results', () => {
    beforeEach(async () => {
      createWrapper();
      findListbox().vm.$emit('search', TEST_SEARCH);
      await axios.waitForAll();
    });

    it('should display a Create item label', () => {
      expect(findCreateEnvironmentButton().text()).toBe(`Create ${TEST_SEARCH}`);
    });

    it('should emit a new scope when selected', () => {
      findCreateEnvironmentButton().vm.$emit('click');
      expect(wrapper.emitted('add')).toEqual([[TEST_SEARCH]]);
    });
  });

  describe('with results', () => {
    beforeEach(async () => {
      createWrapper(['prod', 'production']);
      findListbox().vm.$emit('search', TEST_SEARCH);
      await axios.waitForAll();
    });

    it('should populate results properly', () => {
      expect(findListbox().props().items).toHaveLength(2);
    });

    it('should emit an add on selection', () => {
      findListbox().vm.$emit('select', ['prod']);
      expect(wrapper.emitted('add')).toEqual([['prod']]);
    });

    it('should not display a message about no results', () => {
      expect(wrapper.findComponent({ ref: 'noResults' }).exists()).toBe(false);
    });

    it('should not display a footer with the create button', () => {
      expect(findCreateEnvironmentButton().exists()).toBe(false);
    });
  });
});
