import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefUntrackingConfirmation from '~/security_configuration/components/ref_untracking_confirmation.vue';
import { createTrackedRef } from '../mock_data';

describe('RefUntrackingConfirmation component', () => {
  let wrapper;

  const createComponent = ({ refToUntrack = createTrackedRef() } = {}) => {
    wrapper = shallowMountExtended(RefUntrackingConfirmation, {
      propsData: { refToUntrack },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findVulnerabilityWarning = () => wrapper.findComponent(GlSprintf);

  describe('modal rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each([null, createTrackedRef()])(
      'renders a "GlModal" with correct visibility when refToUntrack is set to "%s"',
      (refToUntrack) => {
        createComponent({ refToUntrack });

        expect(findModal().props('visible')).toBe(refToUntrack !== null);
      },
    );

    it.each`
      refType   | expectedTitle
      ${'HEAD'} | ${'Remove tracking for branch'}
      ${'TAG'}  | ${'Remove tracking for tag'}
    `('displays the correct title for ref of type "$refType"', ({ refType, expectedTitle }) => {
      createComponent({ refToUntrack: createTrackedRef({ refType }) });

      expect(findModal().props('title')).toBe(expectedTitle);
    });
  });

  describe('vulnerability warning', () => {
    it('does not show the warning when vulnerabilitiesCount is 0', () => {
      createComponent({ refToUntrack: createTrackedRef({ vulnerabilitiesCount: 0 }) });

      expect(findVulnerabilityWarning().exists()).toBe(false);
    });

    it('shows the warning when vulnerabilitiesCount is greater than 0', () => {
      createComponent({ refToUntrack: createTrackedRef({ vulnerabilitiesCount: 5 }) });

      expect(findVulnerabilityWarning().exists()).toBe(true);
      expect(findVulnerabilityWarning().attributes('message')).toContain('%{count}');
    });
  });

  describe('user interactions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits "confirm" event with correct payload when primary action is triggered', () => {
      const refToUntrack = createTrackedRef({ id: 'gid://gitlab/TrackedRef/123' });
      createComponent({ refToUntrack });

      findModal().vm.$emit('primary');

      expect(wrapper.emitted('confirm')).toHaveLength(1);
      expect(wrapper.emitted('confirm')[0]).toEqual([
        {
          refId: 'gid://gitlab/TrackedRef/123',
        },
      ]);
    });

    it('emits "cancel" event when modal is hidden', () => {
      findModal().vm.$emit('hidden');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
  });
});
