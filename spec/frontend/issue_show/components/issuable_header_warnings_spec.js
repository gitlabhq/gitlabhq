import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import IssuableHeaderWarnings from '~/issue_show/components/issuable_header_warnings.vue';
import createStore from '~/notes/stores';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IssuableHeaderWarnings', () => {
  let wrapper;
  let store;

  const findConfidential = () => wrapper.find('[data-testid="confidential"]');
  const findLocked = () => wrapper.find('[data-testid="locked"]');
  const confidentialIconName = () => findConfidential().attributes('name');
  const lockedIconName = () => findLocked().attributes('name');

  const createComponent = () => {
    wrapper = shallowMount(IssuableHeaderWarnings, { store, localVue });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
  });

  describe('when confidential is on', () => {
    beforeEach(() => {
      store.state.noteableData.confidential = true;

      createComponent();
    });

    it('renders the confidential icon', () => {
      expect(confidentialIconName()).toBe('eye-slash');
    });
  });

  describe('when confidential is off', () => {
    beforeEach(() => {
      store.state.noteableData.confidential = false;

      createComponent();
    });

    it('does not find the component', () => {
      expect(findConfidential().exists()).toBe(false);
    });
  });

  describe('when discussion locked is on', () => {
    beforeEach(() => {
      store.state.noteableData.discussion_locked = true;

      createComponent();
    });

    it('renders the locked icon', () => {
      expect(lockedIconName()).toBe('lock');
    });
  });

  describe('when discussion locked is off', () => {
    beforeEach(() => {
      store.state.noteableData.discussion_locked = false;

      createComponent();
    });

    it('does not find the component', () => {
      expect(findLocked().exists()).toBe(false);
    });
  });
});
