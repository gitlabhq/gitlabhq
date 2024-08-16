import Vue from 'vue';
import BoolPresenter from '../components/presenters/bool.vue';
import HealthPresenter from '../components/presenters/health.vue';
import LinkPresenter from '../components/presenters/link.vue';
import ListPresenter from '../components/presenters/list.vue';
import NullPresenter from '../components/presenters/null.vue';
import StatePresenter from '../components/presenters/state.vue';
import TablePresenter from '../components/presenters/table.vue';
import TextPresenter from '../components/presenters/text.vue';
import TimePresenter from '../components/presenters/time.vue';

const presentersByFieldName = {
  healthStatus: HealthPresenter,
  state: StatePresenter,
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

  const presenter = presentersByFieldName[fieldName];
  if (presenter) return presenter;

  if (typeof field === 'boolean') return BoolPresenter;
  if (typeof field === 'object') return LinkPresenter;
  if (typeof field === 'string' && field.match(/^\d{4}-\d{2}-\d{2}/) /* date YYYY-MM-DD */)
    return TimePresenter;

  return TextPresenter;
}

export default class Presenter {
  #component;

  // NOTE: This method will eventually start using `this.#config`
  // eslint-disable-next-line class-methods-use-this
  forField(item, fieldName) {
    const field = fieldName === 'title' ? item : item[fieldName];
    const component = componentForField(field, fieldName);

    return {
      render(h) {
        return h(component, { props: { data: field } });
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

  /**
   * Mount the initialized component to the given element
   *
   * @param {Element} element
   * @returns {Vue}
   */
  mount(element) {
    const container = document.createElement('div');
    element.parentNode.replaceChild(container, element);

    const ComponentInstance = Vue.extend(this.#component);

    return new ComponentInstance().$mount(container);
  }

  get component() {
    return this.#component;
  }
}
