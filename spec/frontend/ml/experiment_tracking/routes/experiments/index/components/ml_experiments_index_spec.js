import {
  GlAlert,
  GlAvatar,
  GlAvatarLink,
  GlEmptyState,
  GlKeysetPagination,
  GlLink,
  GlTableLite,
} from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MlExperimentsIndexApp from '~/ml/experiment_tracking/routes/experiments/index';
import ModelExperimentsHeader from '~/ml/experiment_tracking/components/model_experiments_header.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { MLFLOW_USAGE_MODAL_ID } from '~/ml/experiment_tracking/routes/experiments/index/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import getExperimentsQuery from '~/ml/experiment_tracking/graphql/queries/get_experiments.query.graphql';
import {
  firstExperiment,
  secondExperiment,
  MockExperimentsQueryResult,
  MockExperimentsEmptyQueryResult,
} from './mock_data';

Vue.use(VueApollo);

describe('MlExperimentsIndex', () => {
  let wrapper;
  let apolloProvider;

  const createWrapper = async ({
    resolver = jest.fn().mockResolvedValue(MockExperimentsQueryResult),
  } = {}) => {
    const requestHandlers = [[getExperimentsQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountExtended(MlExperimentsIndexApp, {
      apolloProvider,
      directives: { GlModal: createMockDirective('gl-modal') },
      propsData: {
        projectPath: 'group/project',
        emptyStateSvgPath: 'path',
        mlflowTrackingUrl: 'mlflow/tracking/url',
      },
    });

    await waitForPromises();
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findAlert = () => wrapper.findComponent(GlAlert);
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

  describe('empty state', () => {
    const resolver = jest.fn().mockResolvedValue(MockExperimentsEmptyQueryResult);
    beforeEach(() => createWrapper({ resolver }));

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
    beforeEach(() => createWrapper());

    it('has the right title', () => {
      expect(findTitleHeader().props('pageTitle')).toBe('Model experiments');
    });
  });

  describe('experiments table', () => {
    const firstRow = 0;
    const secondRow = 1;
    const thirdRow = 2;
    const nameColumn = 0;
    const candidateCountColumn = 1;
    const creatorColumn = 2;
    const lastActivityColumn = 3;

    beforeEach(() => createWrapper());

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
        ).toBe('2021-08-10T09:33:54Z');
        expect(
          findColumnInRow(secondRow, lastActivityColumn)
            .findComponent(TimeAgoTooltip)
            .props('time'),
        ).toBe('2021-08-10T09:39:54Z');
      });
    });

    describe('experiment creator column', () => {
      it('displays creator avatars and links when creator is not null', () => {
        expect(
          findColumnInRow(firstRow, creatorColumn).findComponent(GlAvatarLink).attributes(),
        ).toMatchObject({
          href: firstExperiment.creator.webUrl,
          title: firstExperiment.creator.name,
        });
        expect(
          findColumnInRow(firstRow, creatorColumn).findComponent(GlAvatar).props(),
        ).toMatchObject({ src: firstExperiment.creator.avatarUrl });

        expect(
          findColumnInRow(secondRow, creatorColumn).findComponent(GlAvatarLink).attributes(),
        ).toMatchObject({
          href: secondExperiment.creator.webUrl,
          title: secondExperiment.creator.name,
        });
        expect(
          findColumnInRow(secondRow, creatorColumn).findComponent(GlAvatar).props(),
        ).toMatchObject({ src: secondExperiment.creator.avatarUrl });
      });

      it('does not display creator avatar and links when creator is null', () => {
        expect(findColumnInRow(thirdRow, creatorColumn).findComponent(GlAvatarLink).exists()).toBe(
          false,
        );
        expect(findColumnInRow(thirdRow, creatorColumn).findComponent(GlAvatar).exists()).toBe(
          false,
        );
      });
    });

    describe('run count column', () => {
      it('shows the run count', () => {
        expect(findColumnInRow(firstRow, candidateCountColumn).text()).toBe(
          `${firstExperiment.candidateCount}`,
        );
        expect(findColumnInRow(secondRow, candidateCountColumn).text()).toBe(
          `${secondExperiment.candidateCount}`,
        );
      });
    });
  });

  describe('pagination', () => {
    describe('Pagination behaviour', () => {
      beforeEach(() => createWrapper());

      it('should show', () => {
        expect(findPagination().exists()).toBe(true);
      });

      it('Passes pagination to pagination component', () => {
        expect(findPagination().props()).toMatchObject({
          endCursor: null,
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
        });
      });
    });
  });

  describe('when loading data fails', () => {
    beforeEach(async () => {
      const error = new Error('Failure!');

      await createWrapper({ resolver: jest.fn().mockRejectedValue(error) });
    });

    it('error message is displayed', () => {
      expect(findAlert().text()).toContain('Failed to load experiments with error: Failure!');
    });

    it('error is logged in sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });
});
