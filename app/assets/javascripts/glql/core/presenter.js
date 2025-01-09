import IterationPresenter from 'ee_else_ce/glql/components/presenters/iteration.vue';
import BoolPresenter from '../components/presenters/bool.vue';
import CollectionPresenter from '../components/presenters/collection.vue';
import HealthPresenter from '../components/presenters/health.vue';
import IssuablePresenter from '../components/presenters/issuable.vue';
import LabelPresenter from '../components/presenters/label.vue';
import LinkPresenter from '../components/presenters/link.vue';
import ListPresenter from '../components/presenters/list.vue';
import MilestonePresenter from '../components/presenters/milestone.vue';
import NullPresenter from '../components/presenters/null.vue';
import HtmlPresenter from '../components/presenters/html.vue';
import StatePresenter from '../components/presenters/state.vue';
import TablePresenter from '../components/presenters/table.vue';
import TextPresenter from '../components/presenters/text.vue';
import TimePresenter from '../components/presenters/time.vue';
import UserPresenter from '../components/presenters/user.vue';

const presentersByObjectType = {
  MergeRequest: IssuablePresenter,
  Issue: IssuablePresenter,
  Epic: IssuablePresenter,
  Milestone: MilestonePresenter,
  MergeRequestAuthor: UserPresenter,
  MergeRequestReviewer: UserPresenter,
  MergeRequestAssignee: UserPresenter,
  UserCore: UserPresenter,
  Label: LabelPresenter,
  Iteration: IterationPresenter,
};

const presentersByFieldName = {
  healthStatus: HealthPresenter,
  state: StatePresenter,
  description: HtmlPresenter,
  descriptionHtml: HtmlPresenter,
};

const presentersByDisplayType = {
  list: ListPresenter,
  orderedList: ListPresenter,

  table: TablePresenter,
};

const olProps = { listType: 'ol' };
const ulProps = { listType: 'ul' };

const additionalPropsByDisplayType = {
  list: ulProps,
  orderedList: olProps,
};

export function componentForField(field, fieldName) {
  if (typeof field === 'undefined' || field === null) return NullPresenter;

  // eslint-disable-next-line no-underscore-dangle
  const presenter = presentersByObjectType[field.__typename] || presentersByFieldName[fieldName];
  if (presenter) return presenter;

  if (typeof field === 'boolean') return BoolPresenter;
  if (typeof field === 'object')
    return Array.isArray(field.nodes) ? CollectionPresenter : LinkPresenter;

  if (typeof field === 'string' && field.match(/^\d{4}-\d{2}-\d{2}/) /* date YYYY-MM-DD */)
    return TimePresenter;

  return TextPresenter;
}

export default class Presenter {
  #config;
  #component;

  forField(item, fieldName) {
    const field = fieldName === 'title' || !fieldName ? item : item[fieldName];
    const component = componentForField(field, fieldName);
    const { source } = this.#config || {};

    return {
      render(h) {
        return h(component, { props: { data: field, source } });
      },
    };
  }

  /**
   * Init the presenter component with given props
   *
   * @param {{ data: any, config: any, ...props: any[] }} props
   * @returns {Presenter}
   */
  init({ data, config, ...props }) {
    const { display } = config;
    const component = presentersByDisplayType[display] || ListPresenter;
    const additionalProps = additionalPropsByDisplayType[display] || {};

    this.#config = config;
    this.#component = {
      provide: {
        presenter: this,
      },
      render: (h) => {
        return h(component, {
          props: { data, config, ...props, ...additionalProps },
        });
      },
    };

    return this;
  }

  get component() {
    return this.#component;
  }
}

export const present = (data, config, ...props) => {
  const presenter = new Presenter().init({ data, config, ...props });
  return presenter.component;
};
