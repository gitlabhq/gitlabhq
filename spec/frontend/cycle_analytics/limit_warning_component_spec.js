import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import Translate from '~/vue_shared/translate';
import LimitWarningComponent from '~/cycle_analytics/components/limit_warning_component.vue';

Vue.use(Translate);

const createComponent = props =>
  shallowMount(LimitWarningComponent, {
    propsData: {
      ...props,
    },
    attachToDocument: true,
  });

describe('Limit warning component', () => {
  let component;

  beforeEach(() => {
    component = null;
  });

  afterEach(() => {
    component.destroy();
  });

  it('should not render if count is not exactly than 50', () => {
    component = createComponent({ count: 5 });

    expect(component.text().trim()).toBe('');

    component = createComponent({ count: 55 });

    expect(component.text().trim()).toBe('');
  });

  it('should render if count is exactly 50', () => {
    component = createComponent({ count: 50 });

    expect(component.text().trim()).toBe('Showing 50 events');
  });
});
