import { shallowMount } from '@vue/test-utils';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import HeaderMetadata from '~/merge_requests/components/header_metadata.vue';
import mrStore from '~/mr_notes/stores';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

describe('HeaderMetadata component', () => {
  let wrapper;

  const findConfidentialBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);

  const renderTestMessage = (renders) => (renders ? 'renders' : 'does not render');

  const createComponent = ({ store, provide }) => {
    wrapper = shallowMount(HeaderMetadata, {
      mocks: {
        $store: store,
      },
      provide,
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

      it(`${renderTestMessage(confidentialStatus)} the confidential badge`, () => {
        const confidentialBadge = findConfidentialBadge();
        expect(confidentialBadge.exists()).toBe(confidentialStatus);

        if (confidentialStatus && !hiddenStatus) {
          expect(confidentialBadge.props()).toMatchObject({
            workspaceType: 'project',
            issuableType: 'issue',
          });
        }
      });

      it(`${renderTestMessage(lockStatus)} the locked badge`, () => {
        expect(findLockedBadge().exists()).toBe(lockStatus);
      });

      it(`${renderTestMessage(hiddenStatus)} the hidden badge`, () => {
        expect(findHiddenBadge().exists()).toBe(hiddenStatus);
      });
    },
  );
});
