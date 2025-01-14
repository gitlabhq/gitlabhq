import { GlAvatar, GlAvatarLink, GlEmptyState, GlLink, GlTableLite } from '@gitlab/ui';
import MlExperimentsIndexApp from '~/ml/experiment_tracking/routes/experiments/index';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import Pagination from '~/ml/experiment_tracking/components/pagination.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { MLFLOW_USAGE_MODAL_ID } from '~/ml/experiment_tracking/routes/experiments/index/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

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
    directives: { GlModal: createMockDirective('gl-modal') },
    propsData: { experiments: defaultExperiments, count: 3, pageInfo, emptyStateSvgPath: 'path' },
  });
};

const findPagination = () => wrapper.findComponent(Pagination);
const findEmptyState = () => wrapper.findComponent(GlEmptyState);
const findTable = () => wrapper.findComponent(GlTableLite);
const findTableHeaders = () => findTable().findAll('th');
const findTableRows = () => findTable().findAll('tbody > tr');
const findNthTableRow = (idx) => findTableRows().at(idx);
const findColumnInRow = (row, col) => findNthTableRow(row).findAll('td').at(col);
const hrefInRowAndColumn = (row, col) =>
  findColumnInRow(row, col).findComponent(GlLink).attributes().href;
const findTitleHeader = () => wrapper.findComponent(ModelExperimentsHeader);
const findDocsButton = () => wrapper.findByTestId('empty-create-using-button');

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

    it('renders header', () => {
      expect(findTitleHeader().exists()).toBe(true);
    });

    it('creates button to docs', () => {
      expect(findDocsButton().text()).toBe('Create an experiment using MLflow');
      expect(getBinding(findDocsButton().element, 'gl-modal').value).toBe(MLFLOW_USAGE_MODAL_ID);
    });
  });

  describe('Title header', () => {
    beforeEach(() => createWrapper(experiments));

    it('has the right title', () => {
      expect(findTitleHeader().props('pageTitle')).toBe('Model experiments');
    });
  });

  describe('experiments table', () => {
    const firstRow = 0;
    const secondRow = 1;
    const nameColumn = 0;
    const candidateCountColumn = 1;
    const creatorColumn = 2;
    const lastActivityColumn = 3;

    beforeEach(() => createWrapper(experiments));

    it('displays the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('sets headers correctly', () => {
      const expectedColumnNames = ['Name', 'Number of runs', 'Creator', 'Last activity'];

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

    describe('experiment last activity column', () => {
      it('displays the last activity column', () => {
        expect(
          findColumnInRow(firstRow, lastActivityColumn).findComponent(TimeAgoTooltip).props('time'),
        ).toBe('2021-04-01');
        expect(
          findColumnInRow(secondRow, lastActivityColumn)
            .findComponent(TimeAgoTooltip)
            .props('time'),
        ).toBe('2021-04-01');
      });
    });

    describe('experiment creator column', () => {
      it('displays creator avatars and links', () => {
        expect(
          findColumnInRow(firstRow, creatorColumn).findComponent(GlAvatarLink).attributes(),
        ).toMatchObject({ href: firstExperiment.user.path, title: firstExperiment.user.name });
        expect(
          findColumnInRow(firstRow, creatorColumn).findComponent(GlAvatar).props(),
        ).toMatchObject({ src: firstExperiment.user.avatar_url });

        expect(
          findColumnInRow(secondRow, creatorColumn).findComponent(GlAvatarLink).attributes(),
        ).toMatchObject({ href: secondExperiment.user.path, title: secondExperiment.user.name });
        expect(
          findColumnInRow(secondRow, creatorColumn).findComponent(GlAvatar).props(),
        ).toMatchObject({ src: secondExperiment.user.avatar_url });
      });
    });

    describe('run count column', () => {
      it('shows the run count', () => {
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
