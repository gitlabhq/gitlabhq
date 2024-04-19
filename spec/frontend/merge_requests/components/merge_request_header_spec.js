import { shallowMount } from '@vue/test-utils';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import StatusBadge from '~/issuable/components/status_badge.vue';
import MergeRequestHeader from '~/merge_requests/components/merge_request_header.vue';
import mrStore from '~/mr_notes/stores';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

describe('MergeRequestHeader component', () => {
  let wrapper;

  const findConfidentialBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findStatusBadge = () => wrapper.findComponent(StatusBadge);

  const renderTestMessage = (renders) => (renders ? 'renders' : 'does not render');

  const createComponent = ({ confidential, hidden, locked, isImported = false }) => {
    const store = mrStore;
    store.getters.getNoteableData = {};
    store.getters.getNoteableData.confidential = confidential;
    store.getters.getNoteableData.discussion_locked = locked;
    store.getters.getNoteableData.targetType = 'merge_request';

    wrapper = shallowMount(MergeRequestHeader, {
      mocks: {
        $store: store,
      },
      provide: {
        hidden,
      },
      propsData: {
        initialState: 'opened',
        isImported,
      },
    });
  };

  it('renders status badge', () => {
    createComponent({ propsData: { initialState: 'opened' } });

    expect(findStatusBadge().props()).toEqual({
      issuableType: 'merge_request',
      state: 'opened',
    });
  });

  describe.each`
    locked   | confidential | hidden
    ${true}  | ${true}      | ${false}
    ${true}  | ${false}     | ${false}
    ${false} | ${true}      | ${false}
    ${false} | ${false}     | ${false}
    ${true}  | ${true}      | ${true}
    ${true}  | ${false}     | ${true}
    ${false} | ${true}      | ${true}
    ${false} | ${false}     | ${true}
  `(
    `when locked=$locked, confidential=$confidential, and hidden=$hidden`,
    ({ locked, confidential, hidden }) => {
      beforeEach(() => {
        createComponent({ confidential, hidden, locked });
      });

      it(`${renderTestMessage(confidential)} the confidential badge`, () => {
        const confidentialBadge = findConfidentialBadge();
        expect(confidentialBadge.exists()).toBe(confidential);

        if (confidential && !hidden) {
          expect(confidentialBadge.props()).toMatchObject({
            workspaceType: 'project',
            issuableType: 'issue',
          });
        }
      });

      it(`${renderTestMessage(locked)} the locked badge`, () => {
        expect(findLockedBadge().exists()).toBe(locked);
      });

      it(`${renderTestMessage(hidden)} the hidden badge`, () => {
        expect(findHiddenBadge().exists()).toBe(hidden);
      });
    },
  );

  describe('imported badge', () => {
    it('renders when merge request is imported', () => {
      createComponent({ isImported: true });

      expect(findImportedBadge().props('importableType')).toBe('merge_request');
    });

    it('does not render when merge request is not imported', () => {
      createComponent({ isImported: false });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });
});
