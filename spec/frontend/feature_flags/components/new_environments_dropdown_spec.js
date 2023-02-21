import { GlTokenSelector } from '@gitlab/ui';
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

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);
  const dropdownItems = () => findTokenSelector().props('dropdownItems');

  const factory = (props = {}) =>
    shallowMount(NewEnvironmentsDropdown, {
      propsData: { selected: [], ...props },
      provide: { environmentsEndpoint: TEST_HOST },
    });

  afterEach(() => {
    axiosMock.restore();

    wrapper = null;
  });

  describe('before results', () => {
    beforeEach(async () => {
      axiosMock = new MockAdapter(axios);
      wrapper = factory();
    });

    it('should show the loading state while fetching environments', async () => {
      expect(findTokenSelector().props('loading')).toBe(false);

      findTokenSelector().vm.$emit('text-input', 'prod');

      await nextTick();

      expect(findTokenSelector().props('loading')).toBe(true);

      await axios.waitForAll();

      expect(findTokenSelector().props('loading')).toBe(false);
    });

    it('should not show any dropdown items', async () => {
      expect(dropdownItems()).toHaveLength(0);
    });
  });

  describe('with empty results', () => {
    beforeEach(async () => {
      axiosMock = new MockAdapter(axios);
      wrapper = factory();

      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, []);

      findTokenSelector().vm.$emit('text-input', TEST_SEARCH);
    });

    it('should display a Create item label', () => {
      expect(wrapper.text()).toContain('Create production');
    });
  });

  describe('with a selected environment', () => {
    beforeEach(async () => {
      axiosMock = new MockAdapter(axios);
      wrapper = factory({ selected: [{ id: 1, name: TEST_SEARCH }] });

      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, []);
    });

    it('should not display a Create item label when item already selected', async () => {
      expect(findTokenSelector().attributes('allowuserdefinedtokens')).toBe('true');

      findTokenSelector().vm.$emit('text-input', TEST_SEARCH);
      await nextTick();

      expect(findTokenSelector().attributes('allowuserdefinedtokens')).toBeUndefined();
    });
  });

  describe('with results', () => {
    beforeEach(async () => {
      axiosMock = new MockAdapter(axios);
      wrapper = factory();

      axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, ['prod', 'production']);
    });

    it('should display one item per result', async () => {
      expect(dropdownItems()).toHaveLength(0);

      findTokenSelector().vm.$emit('text-input', 'prod');
      await axios.waitForAll();

      expect(dropdownItems()).toHaveLength(2);
    });

    it('should emit an add if an item is clicked', () => {
      expect(wrapper.emitted('add')).toBeUndefined();

      findTokenSelector().vm.$emit('token-add', { id: 'fake-id', name: 'prod' });

      expect(wrapper.emitted('add')).toEqual([['prod']]);
    });
  });
});
