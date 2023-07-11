import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '@sentry/browser';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import getServiceDeskIssuesQuery from '~/service_desk/queries/get_service_desk_issues.query.graphql';
import getServiceDeskIssuesCountsQuery from '~/service_desk/queries/get_service_desk_issues_counts.query.graphql';
import ServiceDeskListApp from '~/service_desk/components/service_desk_list_app.vue';
import InfoBanner from '~/service_desk/components/info_banner.vue';
import {
  getServiceDeskIssuesQueryResponse,
  getServiceDeskIssuesCountsQueryResponse,
} from '../mock_data';

jest.mock('@sentry/browser');

describe('ServiceDeskListApp', () => {
  let wrapper;

  Vue.use(VueApollo);

  const defaultProvide = {
    emptyStateSvgPath: 'empty-state.svg',
    isProject: true,
    isSignedIn: true,
    fullPath: 'path/to/project',
    isServiceDeskSupported: true,
    hasAnyIssues: true,
  };

  const defaultQueryResponse = getServiceDeskIssuesQueryResponse;

  const mockServiceDeskIssuesQueryResponse = jest.fn().mockResolvedValue(defaultQueryResponse);
  const mockServiceDeskIssuesCountsQueryResponse = jest
    .fn()
    .mockResolvedValue(getServiceDeskIssuesCountsQueryResponse);

  const findIssuableList = () => wrapper.findComponent(IssuableList);
  const findInfoBanner = () => wrapper.findComponent(InfoBanner);

  const mountComponent = ({
    provide = {},
    data = {},
    serviceDeskIssuesQueryResponse = mockServiceDeskIssuesQueryResponse,
    serviceDeskIssuesCountsQueryResponse = mockServiceDeskIssuesCountsQueryResponse,
    stubs = {},
    mountFn = shallowMount,
  } = {}) => {
    const requestHandlers = [
      [getServiceDeskIssuesQuery, serviceDeskIssuesQueryResponse],
      [getServiceDeskIssuesCountsQuery, serviceDeskIssuesCountsQueryResponse],
    ];

    return mountFn(ServiceDeskListApp, {
      apolloProvider: createMockApollo(
        requestHandlers,
        {},
        {
          typePolicies: {
            Query: {
              fields: {
                project: {
                  merge: true,
                },
              },
            },
          },
        },
      ),
      provide: {
        ...defaultProvide,
        ...provide,
      },
      data() {
        return data;
      },
      stubs,
    });
  };

  beforeEach(() => {
    wrapper = mountComponent();
    return waitForPromises();
  });

  it('fetches service desk issues and renders them in the issuable list', () => {
    expect(findIssuableList().props()).toMatchObject({
      namespace: 'service-desk',
      recentSearchesStorageKey: 'issues',
      issuables: defaultQueryResponse.data.project.issues.nodes,
      tabs: issuableListTabs,
      currentTab: STATUS_OPEN,
      tabCounts: {
        opened: 1,
        closed: 1,
        all: 1,
      },
    });
  });

  describe('InfoBanner', () => {
    it('renders when Service Desk is supported and has any number of issues', () => {
      expect(findInfoBanner().exists()).toBe(true);
    });

    it('does not render, when there are no issues', async () => {
      wrapper = mountComponent({ provide: { hasAnyIssues: false } });
      await waitForPromises();

      expect(findInfoBanner().exists()).toBe(false);
    });
  });

  describe('Events', () => {
    describe('when "click-tab" event is emitted by IssuableList', () => {
      beforeEach(() => {
        mountComponent();

        findIssuableList().vm.$emit('click-tab', STATUS_CLOSED);
      });

      it('updates ui to the new tab', () => {
        expect(findIssuableList().props('currentTab')).toBe(STATUS_CLOSED);
      });
    });
  });

  describe('Errors', () => {
    describe.each`
      error                      | mountOption                               | message
      ${'fetching issues'}       | ${'serviceDeskIssuesQueryResponse'}       | ${ServiceDeskListApp.i18n.errorFetchingIssues}
      ${'fetching issue counts'} | ${'serviceDeskIssuesCountsQueryResponse'} | ${ServiceDeskListApp.i18n.errorFetchingCounts}
    `('when there is an error $error', ({ mountOption, message }) => {
      beforeEach(() => {
        wrapper = mountComponent({
          [mountOption]: jest.fn().mockRejectedValue(new Error('ERROR')),
        });
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(findIssuableList().props('error')).toBe(message);
        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('ERROR'));
      });
    });
  });
});
