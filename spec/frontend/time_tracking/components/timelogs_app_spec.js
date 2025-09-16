import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDatepicker, GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import getTimelogsEmptyResponse from 'test_fixtures/graphql/get_timelogs_empty_response.json';
import getPaginatedTimelogsResponse from 'test_fixtures/graphql/get_paginated_timelogs_response.json';
import getNonPaginatedTimelogsResponse from 'test_fixtures/graphql/get_non_paginated_timelogs_response.json';
import GroupSelect from '~/vue_shared/components/entity_select/group_select.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as urlUtility from '~/lib/utils/url_utility';
import getTimelogsQuery from '~/time_tracking/components/queries/get_timelogs.query.graphql';
import TimelogsApp from '~/time_tracking/components/timelogs_app.vue';
import TimelogsTable from '~/time_tracking/components/timelogs_table.vue';

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  queryToObject: jest.fn(),
  objectToQuery: jest.fn(),
  updateHistory: jest.fn(),
}));

jest.mock('~/api', () => ({
  group: jest.fn().mockResolvedValue({
    id: 123,
    full_name: 'Test Group',
    full_path: 'test-group',
  }),
}));

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
  const findGroupSelect = () => findForm().findComponent(GroupSelect);

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

    Object.defineProperty(window, 'location', {
      writable: true,
      value: {
        ...window.location,
        pathname: '/-/timelogs',
        search: '',
      },
    });

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
    urlUtility.queryToObject.mockReturnValue({});
    urlUtility.objectToQuery.mockReturnValue('');
    urlUtility.updateHistory.mockClear();
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
      const fromDateTime = new Date('2023-02-28');
      const toDateTime = new Date('2023-03-28');

      findUsernameInput().vm.$emit('input', username);
      findFromDatepicker().vm.$emit('input', fromDateTime);
      findToDatepicker().vm.$emit('input', toDateTime);
      findGroupSelect().vm.$emit('input', { id: 123 });

      resolvedEmptyListMock.mockClear();

      submitForm();

      await waitForPromises();

      expect(resolvedEmptyListMock).toHaveBeenCalledWith({
        username,
        startTime: fromDateTime,
        endTime: toDateTime,
        groupId: 'gid://gitlab/Group/123',
        projectId: null,
        first: 20,
        last: null,
        after: null,
        before: null,
      });

      expect(`${wrapper.vm.queryVariables.startTime}`).toEqual(
        'Tue Feb 28 2023 00:00:00 GMT+0000 (Greenwich Mean Time)',
      );
      // should be 1 day ahead of the initial To Date value
      expect(`${wrapper.vm.queryVariables.endTime}`).toEqual(
        'Tue Mar 28 2023 23:59:59 GMT+0000 (Greenwich Mean Time)',
      );

      expect(createAlert).not.toHaveBeenCalled();
      expect(Sentry.captureException).not.toHaveBeenCalled();
    });

    describe('URL parameter handling', () => {
      describe('on initial load', () => {
        it('reads URL parameters and sets form values', () => {
          const urlParams = {
            username: 'testuser',
            group_id: '123',
            project_id: '456',
            from_date: '2023-02-01',
            to_date: '2023-02-28',
          };

          urlUtility.queryToObject.mockReturnValue(urlParams);

          mountComponent();

          expect(urlUtility.queryToObject).toHaveBeenCalledWith(window.location.search);
          expect(findUsernameInput().element.value).toBe('testuser');
          expect(findGroupSelect().props('initialSelection')).toBe('123');
          expect(findFromDatepicker().props('value')).toEqual(new Date('2023-02-01'));
          expect(findToDatepicker().props('value')).toEqual(new Date('2023-02-28'));
        });

        it('auto-runs the report when URL parameters are present', async () => {
          const urlParams = {
            username: 'testuser',
          };

          urlUtility.queryToObject.mockReturnValue(urlParams);

          mountComponent();
          await nextTick();

          expect(resolvedEmptyListMock).toHaveBeenCalledWith(
            expect.objectContaining({
              username: 'testuser',
            }),
          );
        });

        it('does not auto-run the report when no URL parameters are present', async () => {
          urlUtility.queryToObject.mockReturnValue({});

          mountComponent();
          await nextTick();

          // The query is called once for initial load, but not with any filters
          expect(resolvedEmptyListMock).toHaveBeenCalledTimes(1);
          expect(resolvedEmptyListMock).toHaveBeenCalledWith(
            expect.objectContaining({
              username: null,
              groupId: null,
              projectId: null,
            }),
          );
        });

        it('handles partial URL parameters correctly', async () => {
          const urlParams = {
            username: 'testuser',
            from_date: '2023-02-01',
          };

          urlUtility.queryToObject.mockReturnValue(urlParams);

          mountComponent();
          await nextTick();

          expect(findUsernameInput().element.value).toBe('testuser');
          expect(findFromDatepicker().props('value')).toEqual(new Date('2023-02-01'));
          expect(findGroupSelect().props('initialSelection')).toBe(null);
        });
      });

      describe('when running reports', () => {
        it('updates URL parameters when the form is submitted', async () => {
          mountComponent();

          const username = 'johnsmith';
          const fromDateTime = new Date('2023-02-28');
          const toDateTime = new Date('2023-03-28');

          findUsernameInput().vm.$emit('input', username);
          findFromDatepicker().vm.$emit('input', fromDateTime);
          findToDatepicker().vm.$emit('input', toDateTime);
          findGroupSelect().vm.$emit('input', { id: 123 });

          urlUtility.objectToQuery.mockReturnValue(
            'username=johnsmith&group_id=123&from_date=2023-02-28&to_date=2023-03-28',
          );

          submitForm();
          await waitForPromises();

          expect(urlUtility.objectToQuery).toHaveBeenCalledWith({
            username: 'johnsmith',
            group_id: '123',
            from_date: '2023-02-28',
            to_date: '2023-03-28',
          });

          expect(urlUtility.updateHistory).toHaveBeenCalledWith({
            url: '/-/timelogs?username=johnsmith&group_id=123&from_date=2023-02-28&to_date=2023-03-28',
            replace: true,
          });
        });

        it('uses replace for the first update and push for subsequent updates', async () => {
          mountComponent();

          findUsernameInput().vm.$emit('input', 'user1');
          submitForm();
          await waitForPromises();

          expect(urlUtility.updateHistory).toHaveBeenCalledWith(
            expect.objectContaining({ replace: true }),
          );

          findUsernameInput().vm.$emit('input', 'user2');
          submitForm();
          await waitForPromises();

          expect(urlUtility.updateHistory).toHaveBeenLastCalledWith(
            expect.objectContaining({ replace: false }),
          );
        });

        it('removes URL parameters when filters are cleared', async () => {
          mountComponent();

          findUsernameInput().vm.$emit('input', 'testuser');
          submitForm();
          await waitForPromises();

          findUsernameInput().vm.$emit('input', '');
          urlUtility.objectToQuery.mockReturnValue('');

          submitForm();
          await waitForPromises();

          expect(urlUtility.updateHistory).toHaveBeenLastCalledWith({
            url: '/-/timelogs',
            replace: false,
          });
        });

        it('correctly extracts numeric ID from GraphQL ID for group parameter', async () => {
          const urlParams = {
            group_id: '456',
          };

          urlUtility.queryToObject.mockReturnValue(urlParams);

          mountComponent();

          submitForm();

          await waitForPromises();

          expect(urlUtility.objectToQuery).toHaveBeenCalledWith(
            expect.objectContaining({
              group_id: '456',
            }),
          );
        });
      });
    });

    it('runs the query with the correct data after the date filters are cleared', async () => {
      mountComponent();

      const username = 'johnsmith';

      findUsernameInput().vm.$emit('input', username);
      findGroupSelect().vm.$emit('input', { id: 123 });

      await nextTick();

      findFromDatepicker().vm.$emit('clear');
      findToDatepicker().vm.$emit('clear');
      findGroupSelect().vm.$emit('clear');

      resolvedEmptyListMock.mockClear();

      submitForm();

      await waitForPromises();

      expect(resolvedEmptyListMock).toHaveBeenCalledWith({
        username,
        startTime: null,
        endTime: null,
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
