import { mountExtended } from 'helpers/vue_test_utils_helper';
import FieldPresenter from '~/glql/components/presenters/field.vue';
import { dataForField, presenterFor } from '~/glql/components/presenters/presenter_registry';

jest.mock('~/glql/components/presenters/presenter_registry');

describe('FieldPresenter', () => {
  // Render function (rather than `template`) keeps the stub compilable in the
  // Vue 3 jest environment, which doesn't ship the runtime template compiler.
  const StubPresenter = {
    name: 'StubPresenter',
    props: ['item', 'data'],
    render: (h) => h('div'),
  };
  const STUB_DATA = { resolved: true };

  beforeEach(() => {
    presenterFor.mockReturnValue(StubPresenter);
    dataForField.mockReturnValue(STUB_DATA);
  });

  // Full mount (not shallow) so the dynamic <component :is="..."> resolves to
  // StubPresenter rather than a shallow stub that hides its props.
  const mount = (propsData) => mountExtended(FieldPresenter, { propsData });

  it('asks the registry which presenter and data to use', () => {
    const item = { author: 'foo' };
    mount({ item, fieldKey: 'author', variant: 'compact' });

    expect(dataForField).toHaveBeenCalledWith(item, 'author', '');
    expect(presenterFor).toHaveBeenCalledWith(item, 'author', {
      variant: 'compact',
      presenterKey: '',
      parameters: undefined,
    });
  });

  it('passes presenterKey for presenter dispatch when provided', () => {
    const item = { p50: 3661 };
    mount({ item, fieldKey: 'p50', presenterKey: 'durationQuantile', variant: 'default' });

    expect(dataForField).toHaveBeenCalledWith(item, 'p50', 'durationQuantile');
    expect(presenterFor).toHaveBeenCalledWith(item, 'p50', {
      variant: 'default',
      presenterKey: 'durationQuantile',
      parameters: undefined,
    });
  });

  it('mounts the resolved presenter with item and data', () => {
    const item = { author: 'foo' };
    const wrapper = mount({ item, fieldKey: 'author', variant: 'compact' });
    const presenter = wrapper.findComponent(StubPresenter);

    expect(presenter.exists()).toBe(true);
    expect(presenter.props('item')).toBe(item);
    expect(presenter.props('data')).toBe(STUB_DATA);
  });

  describe('with field parameters', () => {
    const parameters = { granularity: 'monthly' };
    const ParametersStub = {
      name: 'ParametersStub',
      props: ['item', 'data', 'parameters'],
      render: (h) => h('div'),
    };

    it('passes them to the registry for dispatch', () => {
      const item = { created: '2026-06-01' };
      mount({ item, fieldKey: 'created', parameters });

      expect(presenterFor).toHaveBeenCalledWith(item, 'created', {
        variant: 'default',
        presenterKey: '',
        parameters,
      });
    });

    it('passes them to the resolved presenter', () => {
      presenterFor.mockReturnValue(ParametersStub);
      const wrapper = mount({ item: { created: '2026-06-01' }, fieldKey: 'created', parameters });

      expect(wrapper.findComponent(ParametersStub).props('parameters')).toEqual(parameters);
    });
  });

  describe('when the presenter declares only some of the props', () => {
    // Object-form props, like every production presenter.
    const DataOnlyStub = {
      name: 'DataOnlyStub',
      props: { data: { type: Object, required: true } },
      render: (h) => h('div'),
    };

    beforeEach(() => {
      presenterFor.mockReturnValue(DataOnlyStub);
    });

    it('binds only the declared props and lets nothing fall through as attributes', () => {
      const wrapper = mount({
        item: { author: 'foo' },
        fieldKey: 'author',
        parameters: { granularity: 'monthly' },
      });
      const presenter = wrapper.findComponent(DataOnlyStub);

      expect(presenter.props()).toEqual({ data: STUB_DATA });
      expect(presenter.attributes()).toEqual({});
    });
  });

  describe('when the presenter declares no props', () => {
    const NoPropsStub = {
      name: 'NoPropsStub',
      render: (h) => h('em'),
    };

    beforeEach(() => {
      presenterFor.mockReturnValue(NoPropsStub);
    });

    it('binds nothing and lets nothing fall through as attributes', () => {
      const wrapper = mount({ item: { author: 'foo' }, fieldKey: 'author' });
      const presenter = wrapper.findComponent(NoPropsStub);

      expect(presenter.props()).toEqual({});
      expect(presenter.attributes()).toEqual({});
    });
  });
});
