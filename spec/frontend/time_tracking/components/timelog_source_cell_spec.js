import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimelogSourceCell from '~/time_tracking/components/timelog_source_cell.vue';
import {
  issuableStatusText,
  STATUS_CLOSED,
  STATUS_MERGED,
  STATUS_OPEN,
  STATUS_LOCKED,
  STATUS_REOPENED,
} from '~/issues/constants';

const createIssuableTimelogMock = (
  type,
  { title, state, webUrl, reference } = {
    title: 'Issuable title',
    state: STATUS_OPEN,
    webUrl: 'https://example.com/issuable_url',
    reference: '#111',
  },
) => {
  return {
    timelog: {
      project: {
        fullPath: 'group/project',
      },
      [type]: {
        title,
        state,
        webUrl,
        reference,
      },
    },
  };
};

describe('TimelogSourceCell component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const findTitleContainer = () => wrapper.findByTestId('title-container');
  const findReferenceContainer = () => wrapper.findByTestId('reference-container');
  const findStateContainer = () => wrapper.findByTestId('state-container');

  const mountComponent = ({ timelog } = {}) => {
    wrapper = shallowMountExtended(TimelogSourceCell, {
      propsData: {
        timelog,
      },
    });
  };

  describe('when the timelog is associated to an issue', () => {
    it('shows the issue title as link to the issue', () => {
      mountComponent(
        createIssuableTimelogMock('issue', {
          title: 'Issue title',
          webUrl: 'https://example.com/issue_url',
        }),
      );

      const titleContainer = findTitleContainer();

      expect(titleContainer.text()).toBe('Issue title');
      expect(titleContainer.attributes('href')).toBe('https://example.com/issue_url');
    });

    it('shows the issue full reference as link to the issue', () => {
      mountComponent(
        createIssuableTimelogMock('issue', {
          reference: '#111',
          webUrl: 'https://example.com/issue_url',
        }),
      );

      const referenceContainer = findReferenceContainer();

      expect(referenceContainer.text()).toBe('group/project#111');
      expect(referenceContainer.attributes('href')).toBe('https://example.com/issue_url');
    });

    it.each`
      state              | stateDescription
      ${STATUS_OPEN}     | ${issuableStatusText[STATUS_OPEN]}
      ${STATUS_REOPENED} | ${issuableStatusText[STATUS_REOPENED]}
      ${STATUS_LOCKED}   | ${issuableStatusText[STATUS_LOCKED]}
      ${STATUS_CLOSED}   | ${issuableStatusText[STATUS_CLOSED]}
    `('shows $stateDescription when the state is $state', ({ state, stateDescription }) => {
      mountComponent(createIssuableTimelogMock('issue', { state }));

      expect(findStateContainer().text()).toBe(stateDescription);
    });
  });

  describe('when the timelog is associated to a merge request', () => {
    it('shows the merge request title as link to the merge request', () => {
      mountComponent(
        createIssuableTimelogMock('mergeRequest', {
          title: 'MR title',
          webUrl: 'https://example.com/mr_url',
        }),
      );

      const titleContainer = findTitleContainer();

      expect(titleContainer.text()).toBe('MR title');
      expect(titleContainer.attributes('href')).toBe('https://example.com/mr_url');
    });

    it('shows the merge request full reference as link to the merge request', () => {
      mountComponent(
        createIssuableTimelogMock('mergeRequest', {
          reference: '!111',
          webUrl: 'https://example.com/mr_url',
        }),
      );

      const referenceContainer = findReferenceContainer();

      expect(referenceContainer.text()).toBe('group/project!111');
      expect(referenceContainer.attributes('href')).toBe('https://example.com/mr_url');
    });
    it.each`
      state            | stateDescription
      ${STATUS_OPEN}   | ${issuableStatusText[STATUS_OPEN]}
      ${STATUS_CLOSED} | ${issuableStatusText[STATUS_CLOSED]}
      ${STATUS_MERGED} | ${issuableStatusText[STATUS_MERGED]}
    `('shows $stateDescription when the state is $state', ({ state, stateDescription }) => {
      mountComponent(createIssuableTimelogMock('mergeRequest', { state }));

      expect(findStateContainer().text()).toBe(stateDescription);
    });
  });
});
