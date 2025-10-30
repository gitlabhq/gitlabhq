import { nextTick } from 'vue';
import { GlModal, GlFormCheckbox, GlBadge, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefUntrackingConfirmation from '~/security_configuration/components/ref_untracking_confirmation.vue';
import { createTrackedRef } from '../mock_data';

describe('RefUntrackingConfirmation component', () => {
  let wrapper;

  const createComponent = ({ refToUntrack = createTrackedRef() } = {}) => {
    wrapper = shallowMountExtended(RefUntrackingConfirmation, {
      propsData: { refToUntrack },
      stubs: { GlSprintf },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findVulnerabilityCountBadge = () => wrapper.findComponent(GlBadge);

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

    it('displays vulnerability count badge', () => {
      const vulnerabilitiesCount = 5;
      createComponent({ refToUntrack: createTrackedRef({ vulnerabilitiesCount }) });

      expect(findVulnerabilityCountBadge().text()).toBe(vulnerabilitiesCount.toString());
      expect(findVulnerabilityCountBadge().props('variant')).toBe('neutral');
    });

    it('displays archive checkbox which is checked by default', () => {
      expect(findCheckbox().attributes('checked')).toBe('true');
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
          archiveVulnerabilities: true,
        },
      ]);
    });

    it('emits "confirm" event with archiveVulnerabilities set to `false` when checkbox is unchecked', async () => {
      const refToUntrack = createTrackedRef({ id: 'gid://gitlab/TrackedRef/123' });
      createComponent({ refToUntrack });

      await findCheckbox().vm.$emit('input', false);
      findModal().vm.$emit('primary');

      expect(wrapper.emitted('confirm')[0]).toEqual([
        {
          refId: 'gid://gitlab/TrackedRef/123',
          archiveVulnerabilities: false,
        },
      ]);
    });

    it('emits "cancel" event when modal is hidden', () => {
      findModal().vm.$emit('hidden');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
  });

  describe('state management', () => {
    it('resets checkbox to be checked by default when', async () => {
      createComponent({ refToUntrack: createTrackedRef() });

      await findCheckbox().vm.$emit('input', false);
      expect(findCheckbox().attributes('checked')).toBeUndefined();

      findModal().vm.$emit('show');
      await nextTick();

      expect(findCheckbox().attributes('checked')).toBe('true');
    });
  });
});
