import { GlEmptyState, GlLink, GlTableLite } from '@gitlab/ui';
import MlExperimentsIndexApp from '~/ml/experiment_tracking/routes/experiments/index';
import IncubationAlert from '~/vue_shared/components/incubation/incubation_alert.vue';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  startCursor,
  firstExperiment,
  secondExperiment,
  experiments,
  defaultPageInfo,
} from './mock_data';

let wrapper;
const createWrapper = (defaultExperiments = [], pageInfo = defaultPageInfo) => {
  wrapper = mountExtended(MlExperimentsIndexApp, {
    propsData: { experiments: defaultExperiments, pageInfo },
  });
};

const findAlert = () => wrapper.findComponent(IncubationAlert);
const findPagination = () => wrapper.findComponent(Pagination);
const findEmptyState = () => wrapper.findComponent(GlEmptyState);
const findTable = () => wrapper.findComponent(GlTableLite);
const findTableHeaders = () => findTable().findAll('th');
const findTableRows = () => findTable().findAll('tbody > tr');
const findNthTableRow = (idx) => findTableRows().at(idx);
const findColumnInRow = (row, col) => findNthTableRow(row).findAll('td').at(col);
const hrefInRowAndColumn = (row, col) =>
  findColumnInRow(row, col).findComponent(GlLink).attributes().href;

describe('MlExperimentsIndex', () => {
  describe('empty state', () => {
    beforeEach(() => createWrapper());

    it('displays empty state when no experiment', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not show table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  it('displays IncubationAlert', () => {
    createWrapper(experiments);

    expect(findAlert().exists()).toBe(true);
  });

  describe('experiments table', () => {
    const firstRow = 0;
    const secondRow = 1;
    const nameColumn = 0;
    const candidateCountColumn = 1;

    beforeEach(() => createWrapper(experiments));

    it('displays the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('sets headers correctly', () => {
      const expectedColumnNames = ['Experiment', 'Logged candidates for experiment'];

      expect(findTableHeaders().wrappers.map((h) => h.text())).toEqual(expectedColumnNames);
    });

    describe('experiment name column', () => {
      it('displays the experiment name', () => {
        expect(findColumnInRow(firstRow, nameColumn).text()).toBe(firstExperiment.name);
        expect(findColumnInRow(secondRow, nameColumn).text()).toBe(secondExperiment.name);
      });

      it('is a link to the experiment', () => {
        expect(hrefInRowAndColumn(firstRow, nameColumn)).toBe(firstExperiment.path);
        expect(hrefInRowAndColumn(secondRow, nameColumn)).toBe(secondExperiment.path);
      });
    });

    describe('candidate count column', () => {
      it('shows the candidate count', () => {
        expect(findColumnInRow(firstRow, candidateCountColumn).text()).toBe(
          `${firstExperiment.candidate_count}`,
        );
        expect(findColumnInRow(secondRow, candidateCountColumn).text()).toBe(
          `${secondExperiment.candidate_count}`,
        );
      });
    });
  });

  describe('pagination', () => {
    describe('Pagination behaviour', () => {
      beforeEach(() => createWrapper(experiments));

      it('should show', () => {
        expect(findPagination().exists()).toBe(true);
      });

      it('Passes pagination to pagination component', () => {
        expect(findPagination().props('startCursor')).toBe(startCursor);
      });
    });
  });
});
