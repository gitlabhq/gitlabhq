import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '@sentry/browser';
import { GlDatepicker, GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import getTimelogsEmptyResponse from 'test_fixtures/graphql/get_timelogs_empty_response.json';
import getPaginatedTimelogsResponse from 'test_fixtures/graphql/get_paginated_timelogs_response.json';
import getNonPaginatedTimelogsResponse from 'test_fixtures/graphql/get_non_paginated_timelogs_response.json';
import { createAlert } from '~/alert';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getTimelogsQuery from '~/time_tracking/components/queries/get_timelogs.query.graphql';
import TimelogsApp from '~/time_tracking/components/timelogs_app.vue';
import TimelogsTable from '~/time_tracking/components/timelogs_table.vue';

jest.mock('~/alert');
jest.mock('@sentry/browser');

describe('Timelogs app', () => {
  Vue.use(VueApollo);

  let wrapper;
  let fakeApollo;

  const findForm = () => wrapper.find('form');
  const findUsernameInput = () => extendedWrapper(findForm()).findByTestId('form-username');
  const findTableContainer = () => wrapper.findByTestId('table-container');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTotalTimeSpentContainer = () => wrapper.findByTestId('total-time-spent-container');
  const findTable = () => wrapper.findComponent(TimelogsTable);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  const findFormDatePicker = (testId) =>
    findForm()
      .findAllComponents(GlDatepicker)
      .filter((c) => c.attributes('data-testid') === testId);
  const findFromDatepicker = () => findFormDatePicker('form-from-date').at(0);
  const findToDatepicker = () => findFormDatePicker('form-to-date').at(0);

  const submitForm = () => findForm().trigger('submit');

  const resolvedEmptyListMock = jest.fn().mockResolvedValue(getTimelogsEmptyResponse);
  const resolvedPaginatedListMock = jest.fn().mockResolvedValue(getPaginatedTimelogsResponse);
  const resolvedNonPaginatedListMock = jest.fn().mockResolvedValue(getNonPaginatedTimelogsResponse);
  const rejectedMock = jest.fn().mockRejectedValue({});

  const mountComponent = ({ props, data } = {}, queryResolverMock = resolvedEmptyListMock) => {
    fakeApollo = createMockApollo([[getTimelogsQuery, queryResolverMock]]);

    wrapper = mountExtended(TimelogsApp, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        limitToHours: false,
        ...props,
      },
      apolloProvider: fakeApollo,
    });
  };

  beforeEach(() => {
    createAlert.mockClear();
    Sentry.captureException.mockClear();
  });

  afterEach(() => {
    fakeApollo = null;
  });

  describe('the content', () => {
    it('shows the form and the loading icon when loading', () => {
      mountComponent();

      expect(findForm().exists()).toBe(true);
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findTableContainer().exists()).toBe(false);
    });

    it('shows the form and the table container when finished loading', async () => {
      mountComponent();

      await waitForPromises();

      expect(findForm().exists()).toBe(true);
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTableContainer().exists()).toBe(true);
    });
  });

  describe('the filter form', () => {
    it('runs the query with the correct data', async () => {
      mountComponent();

      const username = 'johnsmith';
      const fromDate = new Date('2023-02-28');
      const toDate = new Date('2023-03-28');

      findUsernameInput().vm.$emit('input', username);
      findFromDatepicker().vm.$emit('input', fromDate);
      findToDatepicker().vm.$emit('input', toDate);

      resolvedEmptyListMock.mockClear();

      submitForm();

      await waitForPromises();

      expect(resolvedEmptyListMock).toHaveBeenCalledWith({
        username,
        startDate: fromDate,
        endDate: toDate,
        groupId: null,
        projectId: null,
        first: 20,
        last: null,
        after: null,
        before: null,
      });
      expect(createAlert).not.toHaveBeenCalled();
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('runs the query with the correct data after the date filters are cleared', async () => {
      mountComponent();

      const username = 'johnsmith';

      findUsernameInput().vm.$emit('input', username);
      findFromDatepicker().vm.$emit('clear');
      findToDatepicker().vm.$emit('clear');

      resolvedEmptyListMock.mockClear();

      submitForm();

      await waitForPromises();

      expect(resolvedEmptyListMock).toHaveBeenCalledWith({
        username,
        startDate: null,
        endDate: null,
        groupId: null,
        projectId: null,
        first: 20,
        last: null,
        after: null,
        before: null,
      });
      expect(createAlert).not.toHaveBeenCalled();
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    it('shows an alert an logs to sentry when the mutation is rejected', async () => {
      mountComponent({}, rejectedMock);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong. Please try again.',
      });
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('the total time spent container', () => {
    it('is not visible when there are no timelogs', async () => {
      mountComponent();

      await waitForPromises();

      expect(findTotalTimeSpentContainer().exists()).toBe(false);
    });

    it('shows the correct value when `limitToHours` is false', async () => {
      mountComponent({}, resolvedNonPaginatedListMock);

      await waitForPromises();

      expect(findTotalTimeSpentContainer().exists()).toBe(true);
      expect(findTotalTimeSpentContainer().text()).toBe('3d');
    });

    it('shows the correct value when `limitToHours` is true', async () => {
      mountComponent({ props: { limitToHours: true } }, resolvedNonPaginatedListMock);

      await waitForPromises();

      expect(findTotalTimeSpentContainer().exists()).toBe(true);
      expect(findTotalTimeSpentContainer().text()).toBe('24h');
    });
  });

  describe('the table', () => {
    it('gets created with the right props when `limitToHours` is false', async () => {
      mountComponent({}, resolvedNonPaginatedListMock);

      await waitForPromises();

      expect(findTable().props()).toMatchObject({
        limitToHours: false,
        entries: getNonPaginatedTimelogsResponse.data.timelogs.nodes,
      });
    });

    it('gets created with the right props when `limitToHours` is true', async () => {
      mountComponent({ props: { limitToHours: true } }, resolvedNonPaginatedListMock);

      await waitForPromises();

      expect(findTable().props()).toMatchObject({
        limitToHours: true,
        entries: getNonPaginatedTimelogsResponse.data.timelogs.nodes,
      });
    });
  });

  describe('the pagination element', () => {
    it('is not visible whene there is no pagination data', async () => {
      mountComponent({}, resolvedNonPaginatedListMock);

      await waitForPromises();

      expect(findPagination().exists()).toBe(false);
    });

    it('is visible whene there is pagination data', async () => {
      mountComponent({}, resolvedPaginatedListMock);

      await waitForPromises();
      await nextTick();

      expect(findPagination().exists()).toBe(true);
    });
  });
});
