import HealthPresenter from 'ee_else_ce/glql/components/presenters/health.vue';
import IterationPresenter from 'ee_else_ce/glql/components/presenters/iteration.vue';
import StatusPresenter from 'ee_else_ce/glql/components/presenters/status.vue';
import BoolPresenter from '~/glql/components/presenters/bool.vue';
import CiItemPresenter from '~/glql/components/presenters/ci_item.vue';
import CiStatusPresenter from '~/glql/components/presenters/ci_status.vue';
import CodePresenter from '~/glql/components/presenters/code.vue';
import CollectionPresenter from '~/glql/components/presenters/collection.vue';
import DurationPresenter from '~/glql/components/presenters/duration.vue';
import HtmlPresenter from '~/glql/components/presenters/html.vue';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import LabelPresenter from '~/glql/components/presenters/label.vue';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import MilestonePresenter from '~/glql/components/presenters/milestone.vue';
import NamedTextPresenter from '~/glql/components/presenters/named_text.vue';
import NullPresenter from '~/glql/components/presenters/null.vue';
import NumberPresenter from '~/glql/components/presenters/number.vue';
import PercentagePresenter from '~/glql/components/presenters/percentage.vue';
import ProjectPresenter from '~/glql/components/presenters/project.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import TextPresenter from '~/glql/components/presenters/text.vue';
import TimePresenter from '~/glql/components/presenters/time.vue';
import TypePresenter from '~/glql/components/presenters/type.vue';
import UrlPresenter from '~/glql/components/presenters/url.vue';
import UserAvatarPresenter from '~/glql/components/presenters/user_avatar.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import {
  dataForField,
  presenterFor,
  presentersByFieldKey,
  presentersByObjectType,
  titleFieldFor,
} from '~/glql/components/presenters/presenter_registry';
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
  MOCK_MILESTONE,
  MOCK_MR_ASSIGNEES,
  MOCK_MR_AUTHOR,
  MOCK_MR_REVIEWERS,
  MOCK_PIPELINE,
  MOCK_PROJECT,
  MOCK_STATUS,
  MOCK_USER,
  MOCK_WORK_ITEM,
  MOCK_WORK_ITEM_TYPE,
} from '../../mock_data';

const MOCK_LINK = { title: 'title', webUrl: 'url' };

describe('presenter_registry', () => {
  describe('presenterFor', () => {
    it('returns NullPresenter when the resolved field is null', () => {
      expect(presenterFor({ key: null }, 'key')).toBe(NullPresenter);
    });

    describe('typename dispatch (primitive / object types)', () => {
      it.each`
        dataType       | field                   | presenter
        ${'string'}    | ${'text'}               | ${TextPresenter}
        ${'number'}    | ${100}                  | ${TextPresenter}
        ${'boolean'}   | ${true}                 | ${BoolPresenter}
        ${'object'}    | ${MOCK_LINK}            | ${LinkPresenter}
        ${'date'}      | ${'2021-01-01'}         | ${TimePresenter}
        ${'user'}      | ${MOCK_USER}            | ${UserPresenter}
        ${'user'}      | ${MOCK_MR_AUTHOR}       | ${UserPresenter}
        ${'users'}     | ${MOCK_ASSIGNEES}       | ${CollectionPresenter}
        ${'users'}     | ${MOCK_MR_ASSIGNEES}    | ${CollectionPresenter}
        ${'users'}     | ${MOCK_MR_REVIEWERS}    | ${CollectionPresenter}
        ${'label'}     | ${MOCK_LABELS.nodes[0]} | ${LabelPresenter}
        ${'labels'}    | ${MOCK_LABELS}          | ${CollectionPresenter}
        ${'milestone'} | ${MOCK_MILESTONE}       | ${MilestonePresenter}
        ${'issue'}     | ${MOCK_ISSUE}           | ${IssuablePresenter}
        ${'work_item'} | ${MOCK_WORK_ITEM}       | ${IssuablePresenter}
        ${'epic'}      | ${MOCK_EPIC}            | ${IssuablePresenter}
        ${'iteration'} | ${MOCK_ITERATION}       | ${IterationPresenter}
        ${'status'}    | ${MOCK_STATUS}          | ${StatusPresenter}
        ${'type'}      | ${MOCK_WORK_ITEM_TYPE}  | ${TypePresenter}
        ${'pipeline'}  | ${MOCK_PIPELINE}        | ${CiItemPresenter}
        ${'job'}       | ${MOCK_JOB}             | ${CiItemPresenter}
        ${'stage'}     | ${MOCK_CI_STAGE}        | ${NamedTextPresenter}
        ${'project'}   | ${MOCK_PROJECT}         | ${ProjectPresenter}
        ${'group'}     | ${MOCK_GROUP}           | ${LinkPresenter}
      `('resolves $dataType to the matching presenter', ({ field, presenter }) => {
        expect(presenterFor({ key: field }, 'key')).toBe(presenter);
      });
    });

    describe('field-key dispatch', () => {
      it.each`
        fieldKey               | field            | presenter
        ${'user'}              | ${MOCK_USER}     | ${UserPresenter}
        ${'health'}            | ${'onTrack'}     | ${HealthPresenter}
        ${'healthStatus'}      | ${'onTrack'}     | ${HealthPresenter}
        ${'state'}             | ${'opened'}      | ${StatePresenter}
        ${'lastComment'}       | ${'lastComment'} | ${HtmlPresenter}
        ${'type'}              | ${'TASK'}        | ${TypePresenter}
        ${'duration'}          | ${3600}          | ${DurationPresenter}
        ${'webPath'}           | ${'/foo'}        | ${UrlPresenter}
        ${'shortSha'}          | ${'abc123'}      | ${CodePresenter}
        ${'refName'}           | ${'main'}        | ${CodePresenter}
        ${'acceptanceRate'}    | ${0.75}          | ${PercentagePresenter}
        ${'successRate'}       | ${0.95}          | ${PercentagePresenter}
        ${'failureRate'}       | ${0.04}          | ${PercentagePresenter}
        ${'canceledRate'}      | ${0.005}         | ${PercentagePresenter}
        ${'skippedRate'}       | ${0.001}         | ${PercentagePresenter}
        ${'acceptedCount'}     | ${1234}          | ${NumberPresenter}
        ${'rejectedCount'}     | ${567}           | ${NumberPresenter}
        ${'shownCount'}        | ${1801}          | ${NumberPresenter}
        ${'totalCount'}        | ${10000}         | ${NumberPresenter}
        ${'usersCount'}        | ${42}            | ${NumberPresenter}
        ${'suggestionSizeSum'} | ${500000}        | ${NumberPresenter}
        ${'durationQuantile'}  | ${3661}          | ${DurationPresenter}
        ${'queuedDuration'}    | ${90}            | ${DurationPresenter}
      `(
        'resolves field key $fieldKey to the matching presenter',
        ({ fieldKey, field, presenter }) => {
          expect(presenterFor({ [fieldKey]: field }, fieldKey)).toBe(presenter);
        },
      );
    });

    describe('type-scoped field-key dispatch', () => {
      it('resolves status on a CiJob to CiStatusPresenter', () => {
        expect(presenterFor({ __typename: 'CiJob', status: 'SUCCESS' }, 'status')).toBe(
          CiStatusPresenter,
        );
      });

      it('resolves status on a Pipeline to CiStatusPresenter', () => {
        expect(presenterFor({ __typename: 'Pipeline', status: 'FAILED' }, 'status')).toBe(
          CiStatusPresenter,
        );
      });

      it('resolves status on FinishedPipelinesAggregationResponseDimensions to CiStatusPresenter', () => {
        expect(
          presenterFor(
            { __typename: 'FinishedPipelinesAggregationResponseDimensions', status: 'SUCCESS' },
            'status',
          ),
        ).toBe(CiStatusPresenter);
      });

      it('does not resolve status on other typenames to CiStatusPresenter', () => {
        expect(presenterFor({ __typename: 'Issue', status: 'open' }, 'status')).not.toBe(
          CiStatusPresenter,
        );
      });

      it('resolves user on analytics dimensions to UserAvatarPresenter', () => {
        expect(presenterFor({ ...MOCK_DIMENSIONS, user: MOCK_USER }, 'user')).toBe(
          UserAvatarPresenter,
        );
      });

      it('resolves user on other typenames to UserPresenter', () => {
        expect(presenterFor({ user: MOCK_USER }, 'user')).toBe(UserPresenter);
      });

      it('falls back to primitive type for items missing __typename', () => {
        expect(presenterFor({ status: 'open' }, 'status')).toBe(TextPresenter);
      });
    });

    describe('variant dispatch', () => {
      const compact = 'compact';

      it('resolves user field key with compact variant to UserPresenter', () => {
        expect(presenterFor({ user: MOCK_USER }, 'user', compact)).toBe(UserPresenter);
      });

      it('resolves compact even when typename would match a richer presenter', () => {
        expect(presenterFor({ ...MOCK_DIMENSIONS, user: MOCK_USER }, 'user', compact)).toBe(
          UserPresenter,
        );
      });

      it('falls through to typename dispatch when variant has no match', () => {
        expect(presenterFor({ __typename: 'Pipeline', status: 'FAILED' }, 'status', compact)).toBe(
          CiStatusPresenter,
        );
      });

      it('resolves a Project with compact variant to LinkPresenter', () => {
        expect(presenterFor({ key: MOCK_PROJECT }, 'key', compact)).toBe(LinkPresenter);
      });

      it('resolves a Project with default variant to ProjectPresenter', () => {
        expect(presenterFor({ key: MOCK_PROJECT }, 'key')).toBe(ProjectPresenter);
      });
    });

    describe('title-aliased field keys', () => {
      it('routes a Project item by its `name` field through ProjectPresenter', () => {
        expect(presenterFor(MOCK_PROJECT, 'name')).toBe(ProjectPresenter);
      });

      it('still routes an Issue item by its `title` field through IssuablePresenter', () => {
        expect(presenterFor(MOCK_ISSUE, 'title')).toBe(IssuablePresenter);
      });
    });
  });

  describe('dataForField', () => {
    it('returns the item itself when fieldKey is empty', () => {
      expect(dataForField(MOCK_PROJECT, '')).toBe(MOCK_PROJECT);
    });

    it('returns the item itself when fieldKey matches the title alias for its typename', () => {
      expect(dataForField(MOCK_PROJECT, 'name')).toBe(MOCK_PROJECT);
      expect(dataForField(MOCK_ISSUE, 'title')).toBe(MOCK_ISSUE);
    });

    it('returns the field value for non-title field keys', () => {
      expect(dataForField({ key: 'value' }, 'key')).toBe('value');
    });
  });

  describe('titleFieldFor', () => {
    it('returns the alias declared on the typename', () => {
      expect(titleFieldFor('Project')).toBe('name');
    });

    it('falls back to `title` for typenames without an alias', () => {
      expect(titleFieldFor('Issue')).toBe('title');
      expect(titleFieldFor('Unknown')).toBe('title');
      expect(titleFieldFor(undefined)).toBe('title');
    });
  });

  // presenterByFieldKey is checked before presenterByObjectType in the
  // dispatch chain, so a colliding key would intercept the whole-item
  // dataForField shortcut and feed an object to a primitive-shaped presenter.
  it('declares no titleField that collides with presentersByFieldKey', () => {
    const titleFields = Object.values(presentersByObjectType)
      .map((config) => config?.titleField)
      .filter(Boolean);

    titleFields.forEach((field) => {
      expect(presentersByFieldKey).not.toHaveProperty(field);
    });
  });
});
