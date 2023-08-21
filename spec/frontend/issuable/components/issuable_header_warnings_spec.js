import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import mrStore from '~/mr_notes/stores';
import createIssueStore from '~/notes/stores';
import IssuableHeaderWarnings from '~/issuable/components/issuable_header_warnings.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

const ISSUABLE_TYPE_ISSUE = 'issue';
const ISSUABLE_TYPE_MR = 'merge_request';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

describe('IssuableHeaderWarnings', () => {
  let wrapper;

  const findConfidentialIcon = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedIcon = () => wrapper.findByTestId('locked');
  const findHiddenIcon = () => wrapper.findByTestId('hidden');

  const renderTestMessage = (renders) => (renders ? 'renders' : 'does not render');

  const createComponent = ({ store, provide }) => {
    wrapper = shallowMountExtended(IssuableHeaderWarnings, {
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
    issuableType
    ${ISSUABLE_TYPE_ISSUE} | ${ISSUABLE_TYPE_MR}
  `(`when issuableType=$issuableType`, ({ issuableType }) => {
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
        const store = issuableType === ISSUABLE_TYPE_ISSUE ? createIssueStore() : mrStore;

        beforeEach(() => {
          // TODO: simplify to single assignment after issue store is mock
          if (store === mrStore) {
            store.getters.getNoteableData = {};
          }

          store.getters.getNoteableData.confidential = confidentialStatus;
          store.getters.getNoteableData.discussion_locked = lockStatus;
          store.getters.getNoteableData.targetType = issuableType;

          createComponent({ store, provide: { hidden: hiddenStatus } });
        });

        it(`${renderTestMessage(lockStatus)} the locked icon`, () => {
          const lockedIcon = findLockedIcon();

          expect(lockedIcon.exists()).toBe(lockStatus);

          if (lockStatus) {
            expect(lockedIcon.attributes('title')).toBe(
              `This ${issuableType.replace('_', ' ')} is locked. Only project members can comment.`,
            );
            expect(getBinding(lockedIcon.element, 'gl-tooltip')).not.toBeUndefined();
          }
        });

        it(`${renderTestMessage(confidentialStatus)} the confidential icon`, () => {
          const confidentialEl = findConfidentialIcon();
          expect(confidentialEl.exists()).toBe(confidentialStatus);

          if (confidentialStatus && !hiddenStatus) {
            expect(confidentialEl.props()).toMatchObject({
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
              `This ${issuableType.replace('_', ' ')} is hidden because its author has been banned`,
            );
            expect(getBinding(hiddenIcon.element, 'gl-tooltip')).not.toBeUndefined();
          }
        });
      },
    );
  });
});
