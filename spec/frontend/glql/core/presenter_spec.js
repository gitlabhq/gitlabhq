import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoolPresenter from '~/glql/components/presenters/bool.vue';
import HealthPresenter from '~/glql/components/presenters/health.vue';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import LabelPresenter from '~/glql/components/presenters/label.vue';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import MilestonePresenter from '~/glql/components/presenters/milestone.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import TimePresenter from '~/glql/components/presenters/time.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import NullPresenter from '~/glql/components/presenters/null.vue';
import CollectionPresenter from '~/glql/components/presenters/collection.vue';
import IterationPresenter from 'ee_else_ce/glql/components/presenters/iteration.vue';
import Presenter, { componentForField } from '~/glql/core/presenter';
import {
  MOCK_EPIC,
  MOCK_FIELDS,
  MOCK_ISSUE,
  MOCK_ISSUES,
  MOCK_LABELS,
  MOCK_MILESTONE,
  MOCK_USER,
  MOCK_ASSIGNEES,
  MOCK_MR_ASSIGNEES,
  MOCK_MR_REVIEWERS,
  MOCK_ITERATION,
  MOCK_MR_AUTHOR,
} from '../mock_data';

const MOCK_LINK = { title: 'title', webUrl: 'url' };

describe('componentForField', () => {
  it.each`
    dataType       | field                   | presenter              | presenterName
    ${'null'}      | ${null}                 | ${NullPresenter}       | ${'NullPresenter'}
    ${'string'}    | ${'text'}               | ${TextPresenter}       | ${'TextPresenter'}
    ${'number'}    | ${100}                  | ${TextPresenter}       | ${'TextPresenter'}
    ${'boolean'}   | ${true}                 | ${BoolPresenter}       | ${'BoolPresenter'}
    ${'object'}    | ${MOCK_LINK}            | ${LinkPresenter}       | ${'LinkPresenter'}
    ${'date'}      | ${'2021-01-01'}         | ${TimePresenter}       | ${'TimePresenter'}
    ${'user'}      | ${MOCK_USER}            | ${UserPresenter}       | ${'UserPresenter'}
    ${'user'}      | ${MOCK_MR_AUTHOR}       | ${UserPresenter}       | ${'UserPresenter'}
    ${'users'}     | ${MOCK_ASSIGNEES}       | ${CollectionPresenter} | ${'CollectionPresenter'}
    ${'users'}     | ${MOCK_MR_ASSIGNEES}    | ${CollectionPresenter} | ${'CollectionPresenter'}
    ${'users'}     | ${MOCK_MR_REVIEWERS}    | ${CollectionPresenter} | ${'CollectionPresenter'}
    ${'label'}     | ${MOCK_LABELS.nodes[0]} | ${LabelPresenter}      | ${'LabelPresenter'}
    ${'labels'}    | ${MOCK_LABELS}          | ${CollectionPresenter} | ${'CollectionPresenter'}
    ${'milestone'} | ${MOCK_MILESTONE}       | ${MilestonePresenter}  | ${'MilestonePresenter'}
    ${'issue'}     | ${MOCK_ISSUE}           | ${IssuablePresenter}   | ${'IssuablePresenter'}
    ${'epic'}      | ${MOCK_EPIC}            | ${IssuablePresenter}   | ${'IssuablePresenter'}
    ${'iteration'} | ${MOCK_ITERATION}       | ${IterationPresenter}  | ${'IterationPresenter'}
  `('returns $presenterName for data type: $dataType', ({ field, presenter }) => {
    expect(componentForField(field)).toBe(presenter);
  });

  describe('if field name is passed', () => {
    it.each`
      fieldName         | field        | presenter          | presenterName
      ${'healthStatus'} | ${'onTrack'} | ${HealthPresenter} | ${'HealthPresenter'}
      ${'state'}        | ${'opened'}  | ${StatePresenter}  | ${'StatePresenter'}
    `('returns $presenterName for field name: $fieldName', ({ fieldName, field, presenter }) => {
      expect(componentForField(field, fieldName)).toBe(presenter);
    });
  });
});

describe('Presenter', () => {
  it.each`
    displayType      | additionalProps       | PresenterComponent
    ${'list'}        | ${{ listType: 'ul' }} | ${ListPresenter}
    ${'orderedList'} | ${{ listType: 'ol' }} | ${ListPresenter}
    ${'table'}       | ${{}}                 | ${TablePresenter}
  `(
    'inits appropriate presenter component for displayType: $displayType with additionalProps: $additionalProps',
    async ({ displayType, additionalProps, PresenterComponent }) => {
      const element = document.createElement('div');
      element.innerHTML =
        '<pre><code data-canonical-lang="glql">assignee = currentUser()</code></pre>';
      const data = MOCK_ISSUES;
      const config = { display: displayType, fields: MOCK_FIELDS };

      const { component } = await new Presenter().init({ data, config });
      const wrapper = mountExtended(component);
      const presenter = wrapper.findComponent(PresenterComponent);

      expect(presenter.exists()).toBe(true);
      expect(presenter.props('data')).toBe(data);
      expect(presenter.props('config')).toBe(config);
      expect(presenter.props()).toMatchObject(additionalProps);
    },
  );
});
