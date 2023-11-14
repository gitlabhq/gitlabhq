import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import LabelsSelect from '~/admin/abuse_report/components/labels_select.vue';
import ReportDetails from '~/admin/abuse_report/components/report_details.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import abuseReportQuery from '~/admin/abuse_report/graphql/abuse_report.query.graphql';
import { createAlert } from '~/alert';
import { mockAbuseReport, mockLabel1, mockReportQueryResponse } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Report Details', () => {
  let wrapper;
  let fakeApollo;

  const findLabelsSelect = () => wrapper.findComponent(LabelsSelect);

  const abuseReportQueryHandlerSuccess = jest.fn().mockResolvedValue(mockReportQueryResponse);
  const abuseReportQueryHandlerFailure = jest.fn().mockRejectedValue(new Error());

  const createComponent = ({ abuseReportQueryHandler = abuseReportQueryHandlerSuccess } = {}) => {
    fakeApollo = createMockApollo([[abuseReportQuery, abuseReportQueryHandler]]);
    wrapper = shallowMount(ReportDetails, {
      apolloProvider: fakeApollo,
      propsData: {
        reportId: mockAbuseReport.report.globalId,
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  describe('successful abuse report query', () => {
    beforeEach(() => {
      createComponent();
    });

    it('triggers abuse report query', async () => {
      await waitForPromises();

      expect(abuseReportQueryHandlerSuccess).toHaveBeenCalledWith({
        id: mockAbuseReport.report.globalId,
      });
    });

    it('renders LabelsSelect with the fetched report', async () => {
      expect(findLabelsSelect().props('report').labels).toEqual([]);

      await waitForPromises();

      expect(findLabelsSelect().props('report').labels).toEqual([mockLabel1]);
    });
  });

  describe('failed abuse report query', () => {
    beforeEach(async () => {
      createComponent({ abuseReportQueryHandler: abuseReportQueryHandlerFailure });

      await waitForPromises();
    });

    it('creates an alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while fetching labels, please try again.',
      });
    });
  });
});
