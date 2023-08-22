import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderMetadata from '~/merge_requests/components/header_metadata.vue';
import mrStore from '~/mr_notes/stores';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

describe('HeaderMetadata component', () => {
  let wrapper;

  const findConfidentialIcon = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedIcon = () => wrapper.findByTestId('locked');
  const findHiddenIcon = () => wrapper.findByTestId('hidden');

  const renderTestMessage = (renders) => (renders ? 'renders' : 'does not render');

  const createComponent = ({ store, provide }) => {
    wrapper = shallowMountExtended(HeaderMetadata, {
      mocks: {
        $store: store,
      },
      provide,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe.each`
    lockStatus | confidentialStatus | hiddenStatus
    ${true}    | ${true}            | ${false}
    ${true}    | ${false}           | ${false}
    ${false}   | ${true}            | ${false}
    ${false}   | ${false}           | ${false}
    ${true}    | ${true}            | ${true}
    ${true}    | ${false}           | ${true}
    ${false}   | ${true}            | ${true}
    ${false}   | ${false}           | ${true}
  `(
    `when locked=$lockStatus, confidential=$confidentialStatus, and hidden=$hiddenStatus`,
    ({ lockStatus, confidentialStatus, hiddenStatus }) => {
      const store = mrStore;

      beforeEach(() => {
        store.getters.getNoteableData = {};
        store.getters.getNoteableData.confidential = confidentialStatus;
        store.getters.getNoteableData.discussion_locked = lockStatus;
        store.getters.getNoteableData.targetType = 'merge_request';

        createComponent({ store, provide: { hidden: hiddenStatus } });
      });

      it(`${renderTestMessage(lockStatus)} the locked icon`, () => {
        const lockedIcon = findLockedIcon();

        expect(lockedIcon.exists()).toBe(lockStatus);

        if (lockStatus) {
          expect(lockedIcon.attributes('title')).toBe(
            `This merge request is locked. Only project members can comment.`,
          );
          expect(getBinding(lockedIcon.element, 'gl-tooltip')).not.toBeUndefined();
        }
      });

      it(`${renderTestMessage(confidentialStatus)} the confidential icon`, () => {
        const confidentialIcon = findConfidentialIcon();
        expect(confidentialIcon.exists()).toBe(confidentialStatus);

        if (confidentialStatus && !hiddenStatus) {
          expect(confidentialIcon.props()).toMatchObject({
            workspaceType: 'project',
            issuableType: 'issue',
          });
        }
      });

      it(`${renderTestMessage(confidentialStatus)} the hidden icon`, () => {
        const hiddenIcon = findHiddenIcon();

        expect(hiddenIcon.exists()).toBe(hiddenStatus);

        if (hiddenStatus) {
          expect(hiddenIcon.attributes('title')).toBe(
            `This merge request is hidden because its author has been banned`,
          );
          expect(getBinding(hiddenIcon.element, 'gl-tooltip')).not.toBeUndefined();
        }
      });
    },
  );
});
