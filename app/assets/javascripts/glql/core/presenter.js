import Vue from 'vue';
import LinkPresenter from '../components/presenters/link.vue';
import TextPresenter from '../components/presenters/text.vue';
import ListPresenter from '../components/presenters/list.vue';
import NullPresenter from '../components/presenters/null.vue';

const presentersByDisplayType = {
  list: ListPresenter,
  orderedList: ListPresenter,
};

const olProps = { listType: 'ol' };
const ulProps = { listType: 'ul' };

const additionalPropsByDisplayType = {
  list: ulProps,
  orderedList: olProps,
};

export function componentForField(field) {
  if (typeof field === 'undefined' || field === null) return NullPresenter;
  if (typeof field === 'object') return LinkPresenter;

  return TextPresenter;
}

export default class Presenter {
  #component;

  // NOTE: This method will eventually start using `this.#config`
  // eslint-disable-next-line class-methods-use-this
  forField(item, fieldName) {
    const field = fieldName === 'title' ? item : item[fieldName];
    const component = componentForField(field);

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
