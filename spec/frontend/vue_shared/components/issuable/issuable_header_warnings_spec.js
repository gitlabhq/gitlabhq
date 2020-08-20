import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import IssuableHeaderWarnings from '~/vue_shared/components/issuable/issuable_header_warnings.vue';
import createIssueStore from '~/notes/stores';
import { createStore as createMrStore } from '~/mr_notes/stores';

const ISSUABLE_TYPE_ISSUE = 'issue';
const ISSUABLE_TYPE_MR = 'merge request';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IssuableHeaderWarnings', () => {
  let wrapper;
  let store;

  const findConfidentialIcon = () => wrapper.find('[data-testid="confidential"]');
  const findLockedIcon = () => wrapper.find('[data-testid="locked"]');

  const renderTestMessage = renders => (renders ? 'renders' : 'does not render');

  const setLock = locked => {
    store.getters.getNoteableData.discussion_locked = locked;
  };

  const setConfidential = confidential => {
    store.getters.getNoteableData.confidential = confidential;
  };

  const createComponent = () => {
    wrapper = shallowMount(IssuableHeaderWarnings, { store, localVue });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
  });

  describe.each`
    issuableType
    ${ISSUABLE_TYPE_ISSUE} | ${ISSUABLE_TYPE_MR}
  `(`when issuableType=$issuableType`, ({ issuableType }) => {
    beforeEach(() => {
      store = issuableType === ISSUABLE_TYPE_ISSUE ? createIssueStore() : createMrStore();
      createComponent();
    });

    describe.each`
      lockStatus | confidentialStatus
      ${true}    | ${true}
      ${true}    | ${false}
      ${false}   | ${true}
      ${false}   | ${false}
    `(
      `when locked=$lockStatus and confidential=$confidentialStatus`,
      ({ lockStatus, confidentialStatus }) => {
        beforeEach(() => {
          setLock(lockStatus);
          setConfidential(confidentialStatus);
        });

        it(`${renderTestMessage(lockStatus)} the locked icon`, () => {
          expect(findLockedIcon().exists()).toBe(lockStatus);
        });

        it(`${renderTestMessage(confidentialStatus)} the confidential icon`, () => {
          expect(findConfidentialIcon().exists()).toBe(confidentialStatus);
        });
      },
    );
  });
});
