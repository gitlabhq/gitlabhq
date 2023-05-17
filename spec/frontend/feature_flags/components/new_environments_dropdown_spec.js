import { GlLoadingIcon, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import NewEnvironmentsDropdown from '~/feature_flags/components/new_environments_dropdown.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const TEST_HOST = '/test';
const TEST_SEARCH = 'production';

describe('New Environments Dropdown', () => {
  let wrapper;
  let axiosMock;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    wrapper = shallowMount(NewEnvironmentsDropdown, {
      provide: { environmentsEndpoint: TEST_HOST },
    });
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('before results', () => {
    it('should show a loading icon', () => {
      axiosMock.onGet(TEST_HOST).reply(() => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });
      wrapper.findComponent(GlSearchBoxByType).vm.$emit('focus');
      return axios.waitForAll();
    });

    it('should not show any dropdown items', () => {
      axiosMock.onGet(TEST_HOST).reply(() => {
        expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(0);
      });
      wrapper.findComponent(GlSearchBoxByType).vm.$emit('focus');
      return axios.waitForAll();
    });
  });

  describe('with empty results', () => {
    let item;
    beforeEach(async () => {
      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, []);
      wrapper.findComponent(GlSearchBoxByType).vm.$emit('focus');
      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', TEST_SEARCH);
      await axios.waitForAll();
      await nextTick();
      item = wrapper.findComponent(GlDropdownItem);
    });

    it('should display a Create item label', () => {
      expect(item.text()).toBe('Create production');
    });

    it('should display that no matching items are found', () => {
      expect(wrapper.findComponent({ ref: 'noResults' }).exists()).toBe(true);
    });

    it('should emit a new scope when selected', () => {
      item.vm.$emit('click');
      expect(wrapper.emitted('add')).toEqual([[TEST_SEARCH]]);
    });
  });

  describe('with results', () => {
    let items;
    beforeEach(() => {
      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, ['prod', 'production']);
      wrapper.findComponent(GlSearchBoxByType).vm.$emit('focus');
      wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'prod');
      return axios.waitForAll().then(() => {
        items = wrapper.findAllComponents(GlDropdownItem);
      });
    });

    it('should display one item per result', () => {
      expect(items).toHaveLength(2);
    });

    it('should emit an add if an item is clicked', () => {
      items.at(0).vm.$emit('click');
      expect(wrapper.emitted('add')).toEqual([['prod']]);
    });

    it('should not display a create label', () => {
      items = items.filter((i) => i.text().startsWith('Create'));
      expect(items).toHaveLength(0);
    });

    it('should not display a message about no results', () => {
      expect(wrapper.findComponent({ ref: 'noResults' }).exists()).toBe(false);
    });
  });
});
