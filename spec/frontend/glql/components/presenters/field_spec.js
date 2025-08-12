import { mountExtended } from 'helpers/vue_test_utils_helper';
import FieldPresenter from '~/glql/components/presenters/field.vue';
import HealthPresenter from 'ee_else_ce/glql/components/presenters/health.vue';
import IterationPresenter from 'ee_else_ce/glql/components/presenters/iteration.vue';
import StatusPresenter from 'ee_else_ce/glql/components/presenters/status.vue';
import DimensionPresenter from '~/glql/components/presenters/dimension.vue';
import BoolPresenter from '~/glql/components/presenters/bool.vue';
import HtmlPresenter from '~/glql/components/presenters/html.vue';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import LabelPresenter from '~/glql/components/presenters/label.vue';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import MilestonePresenter from '~/glql/components/presenters/milestone.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import TimePresenter from '~/glql/components/presenters/time.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import NullPresenter from '~/glql/components/presenters/null.vue';
import CollectionPresenter from '~/glql/components/presenters/collection.vue';
import TypePresenter from '~/glql/components/presenters/type.vue';
import {
  MOCK_EPIC,
  MOCK_ISSUE,
  MOCK_LABELS,
  MOCK_MILESTONE,
  MOCK_USER,
  MOCK_ASSIGNEES,
  MOCK_MR_ASSIGNEES,
  MOCK_MR_REVIEWERS,
  MOCK_ITERATION,
  MOCK_MR_AUTHOR,
  MOCK_WORK_ITEM,
  MOCK_STATUS,
  MOCK_WORK_ITEM_TYPE,
  MOCK_DIMENSION,
} from '../../mock_data';

const MOCK_LINK = { title: 'title', webUrl: 'url' };

describe('FieldPresenter', () => {
  let wrapper;
  const createWrapper = (field, fieldKey) => {
    wrapper = mountExtended(FieldPresenter, {
      propsData: { item: field, fieldKey },
    });
  };

  const propsOrAttributes = (component, propOrAttribute) => {
    return component.props(propOrAttribute) || component.attributes(propOrAttribute);
  };

  it.each`
    dataType       | field                   | presenter              | presenterName
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
    ${'work_item'} | ${MOCK_WORK_ITEM}       | ${IssuablePresenter}   | ${'IssuablePresenter'}
    ${'epic'}      | ${MOCK_EPIC}            | ${IssuablePresenter}   | ${'IssuablePresenter'}
    ${'iteration'} | ${MOCK_ITERATION}       | ${IterationPresenter}  | ${'IterationPresenter'}
    ${'status'}    | ${MOCK_STATUS}          | ${StatusPresenter}     | ${'StatusPresenter'}
    ${'type'}      | ${MOCK_WORK_ITEM_TYPE}  | ${TypePresenter}       | ${'TypePresenter'}
    ${'dimension'} | ${MOCK_DIMENSION}       | ${DimensionPresenter}  | ${'DimensionPresenter'}
  `('renders $presenterName for data type: $dataType', ({ field, presenter }) => {
    createWrapper({ key: field }, 'key');

    const component = wrapper.findComponent(presenter);

    expect(propsOrAttributes(component, 'item')).toBeDefined();
    expect(propsOrAttributes(component, 'data')).toBeDefined();
    expect(propsOrAttributes(component, 'field-key')).toBe('key');
  });

  it('renders NullPresenter for null data', () => {
    createWrapper({ key: null }, 'key');
    const component = wrapper.findComponent(NullPresenter);

    expect(component.exists()).toBe(true);
    expect(propsOrAttributes(component, 'data')).not.toBeDefined();
  });

  describe('if fieldKey is passed', () => {
    it.each`
      fieldKey          | field            | presenter          | presenterName
      ${'health'}       | ${'onTrack'}     | ${HealthPresenter} | ${'HealthPresenter'}
      ${'healthStatus'} | ${'onTrack'}     | ${HealthPresenter} | ${'HealthPresenter'}
      ${'state'}        | ${'opened'}      | ${StatePresenter}  | ${'StatePresenter'}
      ${'lastComment'}  | ${'lastComment'} | ${HtmlPresenter}   | ${'HtmlPresenter'}
      ${'type'}         | ${'TASK'}        | ${TypePresenter}   | ${'TypePresenter'}
    `('renders $presenterName for field key: $fieldKey', ({ fieldKey, field, presenter }) => {
      createWrapper({ [fieldKey]: field }, fieldKey);

      const component = wrapper.findComponent(presenter);

      expect(propsOrAttributes(component, 'item')).toBeDefined();
      expect(propsOrAttributes(component, 'data')).toBe(field);
      expect(propsOrAttributes(component, 'field-key')).toBe(fieldKey);
    });
  });
});
