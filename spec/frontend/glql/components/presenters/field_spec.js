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

    expect(dataForField).toHaveBeenCalledWith(item, 'author');
    expect(presenterFor).toHaveBeenCalledWith(item, 'author', 'compact');
  });

  it('mounts the resolved presenter with item and data', () => {
    const item = { author: 'foo' };
    const wrapper = mount({ item, fieldKey: 'author', variant: 'compact' });
    const presenter = wrapper.findComponent(StubPresenter);

    expect(presenter.exists()).toBe(true);
    expect(presenter.props('item')).toBe(item);
    expect(presenter.props('data')).toBe(STUB_DATA);
  });
});
