import Vue from 'vue';
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createStore as createMrStore } from '~/mr_notes/stores';
import createIssueStore from '~/notes/stores';
import IssuableHeaderWarnings from '~/issuable/components/issuable_header_warnings.vue';

const ISSUABLE_TYPE_ISSUE = 'issue';
const ISSUABLE_TYPE_MR = 'merge_request';

Vue.use(Vuex);

describe('IssuableHeaderWarnings', () => {
  let wrapper;

  const findConfidentialIcon = () => wrapper.findByTestId('confidential');
  const findLockedIcon = () => wrapper.findByTestId('locked');
  const findHiddenIcon = () => wrapper.findByTestId('hidden');

  const renderTestMessage = (renders) => (renders ? 'renders' : 'does not render');

  const createComponent = ({ store, provide }) => {
    wrapper = shallowMountExtended(IssuableHeaderWarnings, {
      store,
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
        const store = issuableType === ISSUABLE_TYPE_ISSUE ? createIssueStore() : createMrStore();

        beforeEach(() => {
          store.getters.getNoteableData.confidential = confidentialStatus;
          store.getters.getNoteableData.discussion_locked = lockStatus;
          store.getters.getNoteableData.targetType = issuableType;

          createComponent({ store, provide: { hidden: hiddenStatus } });
        });

        it(`${renderTestMessage(lockStatus)} the locked icon`, () => {
          expect(findLockedIcon().exists()).toBe(lockStatus);
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
