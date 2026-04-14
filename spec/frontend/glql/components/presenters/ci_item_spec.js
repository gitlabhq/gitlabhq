import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import CiItemPresenter from '~/glql/components/presenters/ci_item.vue';
import { MOCK_JOB, MOCK_PIPELINE } from '../../mock_data';

describe('CiItemPresenter', () => {
  const createWrapper = (data) => shallowMountExtended(CiItemPresenter, { propsData: { data } });

  describe('link rendering', () => {
    it('renders a link using webPath', () => {
      const wrapper = createWrapper(MOCK_JOB);
      const link = wrapper.findComponent(GlLink);

      expect(link.attributes('href')).toBe(MOCK_JOB.webPath);
    });

    it('renders a link using path as fallback', () => {
      const wrapper = createWrapper(MOCK_PIPELINE);
      const link = wrapper.findComponent(GlLink);

      expect(link.attributes('href')).toBe(MOCK_PIPELINE.path);
    });

    it('renders a span when no URL is available', () => {
      const wrapper = createWrapper({ __typename: 'CiJob', name: 'test' });

      expect(wrapper.findComponent(GlLink).exists()).toBe(false);
      expect(wrapper.text()).toContain('test');
    });
  });

  describe('label', () => {
    it('shows id and name when both are present', () => {
      const wrapper = createWrapper(MOCK_JOB);

      expect(wrapper.text()).toContain(`#${MOCK_JOB.id}: ${MOCK_JOB.name}`);
    });

    it('shows only name when id is missing', () => {
      const wrapper = createWrapper({ __typename: 'CiJob', name: 'test', webPath: '/test' });

      expect(wrapper.text()).toBe('test');
    });

    it('shows only id when name is missing', () => {
      const wrapper = createWrapper({ __typename: 'CiJob', id: 123, webPath: '/test' });

      expect(wrapper.text()).toBe('#123');
    });
  });

  describe('status icon', () => {
    it('renders CiIcon when status is present', () => {
      const wrapper = createWrapper(MOCK_JOB);
      const ciIcon = wrapper.findComponent(CiIcon);

      expect(ciIcon.exists()).toBe(true);
      expect(ciIcon.props('status')).toEqual({ icon: 'status_failed', text: 'Failed' });
    });

    it('does not render CiIcon when status is absent', () => {
      const wrapper = createWrapper({ __typename: 'CiJob', name: 'test', webPath: '/test' });

      expect(wrapper.findComponent(CiIcon).exists()).toBe(false);
    });
  });
});
