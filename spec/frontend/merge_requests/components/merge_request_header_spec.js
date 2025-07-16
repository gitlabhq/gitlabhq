import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import StatusBadge from '~/issuable/components/status_badge.vue';
import MergeRequestHeader from '~/merge_requests/components/merge_request_header.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

Vue.use(PiniaVuePlugin);

describe('MergeRequestHeader component', () => {
  let pinia;
  let wrapper;

  const findConfidentialBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findStatusBadge = () => wrapper.findComponent(StatusBadge);

  const renderTestMessage = (renders) => (renders ? 'renders' : 'does not render');

  const createComponent = ({ confidential, hidden, locked, isImported = false }) => {
    useNotes().noteableData.confidential = confidential;
    useNotes().noteableData.discussion_locked = locked;
    useNotes().noteableData.targetType = 'merge_request';

    wrapper = shallowMount(MergeRequestHeader, {
      pinia,
      provide: {
        hidden,
      },
      propsData: {
        initialState: 'opened',
        isImported,
        isDraft: false,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  it('renders status badge', () => {
    createComponent({ propsData: { initialState: 'opened' } });

    expect(findStatusBadge().props()).toEqual({
      issuableType: 'merge_request',
      state: 'opened',
      isDraft: false,
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

      expect(findImportedBadge().exists()).toBe(true);
    });

    it('does not render when merge request is not imported', () => {
      createComponent({ isImported: false });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });
});
