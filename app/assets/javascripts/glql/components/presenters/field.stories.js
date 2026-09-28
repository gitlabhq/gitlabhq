import {
  MOCK_ASSIGNEES,
  MOCK_CI_STAGE,
  MOCK_DIMENSIONS,
  MOCK_EPIC,
  MOCK_GROUP,
  MOCK_ISSUE,
  MOCK_ITERATION,
  MOCK_JOB,
  MOCK_LABELS,
  MOCK_LINK,
  MOCK_MERGE_REQUEST,
  MOCK_MILESTONE,
  MOCK_PIPELINE,
  MOCK_PROJECT,
  MOCK_STATUS,
  MOCK_USER,
  MOCK_WORK_ITEM_TYPE,
} from 'jest/glql/mock_data';
import FieldPresenter from './field.vue';

const ISSUE = (fields) => ({ ...MOCK_ISSUE, ...fields });
const DIMENSIONS = (fields) => ({ ...MOCK_DIMENSIONS, ...fields });

// `field.vue` resolves a presenter per (item, fieldKey) rather than taking one,
// so the gallery is a list of inputs with the presenter each one should reach.
// One row per presenter in `presenter_registry.js` — the registry maps many
// field keys onto the same presenter, so the rows are representative, not
// exhaustive.
//
// `health`, `status` and `iteration` resolve through `ee_else_ce`, so those
// rows render the real presenter under EE and a stub under FOSS.
const GROUPS = [
  {
    name: 'Issuables and objects',
    cases: [
      { presenter: 'IssuablePresenter', item: MOCK_ISSUE, fieldKey: 'title' },
      {
        presenter: 'IssuablePresenter (merge request)',
        item: MOCK_MERGE_REQUEST,
        fieldKey: 'title',
      },
      { presenter: 'IssuablePresenter (epic)', item: MOCK_EPIC, fieldKey: 'title' },
      { presenter: 'MilestonePresenter', item: MOCK_MILESTONE, fieldKey: 'title' },
      { presenter: 'IterationPresenter', item: MOCK_ITERATION, fieldKey: 'title' },
      { presenter: 'ProjectPresenter', item: MOCK_PROJECT, fieldKey: 'name' },
      { presenter: 'LinkPresenter (group)', item: MOCK_GROUP, fieldKey: 'title' },
      { presenter: 'LabelPresenter', item: MOCK_LABELS.nodes[0], fieldKey: 'title' },
      { presenter: 'TypePresenter', item: ISSUE({ type: MOCK_WORK_ITEM_TYPE }), fieldKey: 'type' },
      { presenter: 'StatusPresenter', item: ISSUE({ status: MOCK_STATUS }), fieldKey: 'status' },
    ],
  },
  {
    name: 'Users',
    cases: [
      { presenter: 'UserPresenter', item: ISSUE({ author: MOCK_USER }), fieldKey: 'author' },
      { presenter: 'UserAvatarPresenter', item: MOCK_DIMENSIONS, fieldKey: 'user' },
      {
        presenter: 'CollectionPresenter',
        item: ISSUE({ assignees: MOCK_ASSIGNEES }),
        fieldKey: 'assignees',
      },
    ],
  },
  {
    name: 'CI',
    cases: [
      { presenter: 'CiItemPresenter (pipeline)', item: MOCK_PIPELINE, fieldKey: 'title' },
      { presenter: 'CiItemPresenter (job)', item: MOCK_JOB, fieldKey: 'title' },
      { presenter: 'CiStatusPresenter', item: MOCK_PIPELINE, fieldKey: 'status' },
      { presenter: 'NamedTextPresenter', item: MOCK_CI_STAGE, fieldKey: 'title' },
      {
        presenter: 'CodePresenter',
        item: ISSUE({ sourceBranch: 'ek-add-glql-field-presenter-gallery' }),
        fieldKey: 'sourceBranch',
      },
      { presenter: 'UrlPresenter', item: MOCK_JOB, fieldKey: 'webPath' },
    ],
  },
  {
    name: 'Metrics and values',
    cases: [
      {
        presenter: 'NumberPresenter',
        item: DIMENSIONS({ totalCount: 12345 }),
        fieldKey: 'totalCount',
      },
      {
        presenter: 'PercentagePresenter',
        item: DIMENSIONS({ acceptanceRate: 0.625 }),
        fieldKey: 'acceptanceRate',
      },
      {
        presenter: 'DurationPresenter',
        item: DIMENSIONS({ duration: 3675 }),
        fieldKey: 'duration',
      },
      {
        presenter: 'DurationPresenter (quantile)',
        item: DIMENSIONS({ timeToMergeQuantile: 90061 }),
        fieldKey: 'timeToMergeQuantile',
      },
      { presenter: 'StatePresenter', item: MOCK_ISSUE, fieldKey: 'state' },
      {
        presenter: 'HealthPresenter',
        item: ISSUE({ healthStatus: 'onTrack' }),
        fieldKey: 'healthStatus',
      },
      {
        presenter: 'HtmlPresenter',
        item: ISSUE({ description: '<p>Rendered <strong>description</strong> HTML.</p>' }),
        fieldKey: 'description',
      },
    ],
  },
  {
    name: 'Primitives and fallbacks',
    cases: [
      { presenter: 'BoolPresenter', item: ISSUE({ confidential: true }), fieldKey: 'confidential' },
      {
        presenter: 'TimePresenter',
        item: ISSUE({ createdAt: '2026-09-01T09:16:20Z' }),
        fieldKey: 'createdAt',
      },
      { presenter: 'TextPresenter', item: MOCK_ISSUE, fieldKey: 'reference' },
      {
        presenter: 'LinkPresenter (plain object)',
        item: ISSUE({ related: MOCK_LINK }),
        fieldKey: 'related',
      },
      { presenter: 'NullPresenter', item: ISSUE({ assignee: null }), fieldKey: 'assignee' },
    ],
  },
];

export default {
  component: FieldPresenter,
  title: 'glql/components/presenters/field',
  argTypes: {
    groups: { control: false, description: 'Gallery rows, grouped by kind of field.' },
    variant: {
      control: 'select',
      options: ['default', 'compact'],
      description: 'Registry variant. Only some entries declare one.',
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { FieldPresenter },
  props: Object.keys(argTypes),
  template: `<div class="gl-flex gl-flex-col gl-gap-5">
    <section v-for="group in groups" :key="group.name">
      <h3 class="gl-heading-4">{{ group.name }}</h3>
      <table>
        <tbody>
          <tr v-for="row in group.cases" :key="row.presenter">
            <td class="gl-py-2 gl-pr-5 gl-align-top gl-text-subtle">{{ row.presenter }}</td>
            <td class="gl-py-2 gl-pr-5 gl-align-top"><code>{{ row.fieldKey }}</code></td>
            <td class="gl-py-2 gl-align-top">
              <field-presenter :item="row.item" :field-key="row.fieldKey" :variant="variant" />
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>`,
});

export const Default = Template.bind({});
Default.args = {
  groups: GROUPS,
  variant: 'default',
};

// Only `Project` and the `user` field key declare a compact variant, so every
// other row is unchanged.
export const Compact = Template.bind({});
Compact.args = {
  ...Default.args,
  variant: 'compact',
};

// An aliased field stores its value under the alias, so the data key and the
// registry key come apart and `presenterKey` has to carry the latter.
const AliasTemplate = (args, { argTypes }) => ({
  components: { FieldPresenter },
  props: Object.keys(argTypes),
  template: `<field-presenter :item="item" :field-key="fieldKey" :presenter-key="presenterKey" />`,
});

export const AliasedField = AliasTemplate.bind({});
AliasedField.args = {
  item: DIMENSIONS({ acceptedShare: 0.625 }),
  fieldKey: 'acceptedShare',
  presenterKey: 'acceptanceRate',
};
AliasedField.argTypes = {
  item: { control: false },
  fieldKey: { control: 'text' },
  presenterKey: { control: 'text' },
};
