import { propsUnion } from '~/vue_shared/components/lib/utils/props_utils';

describe('propsUnion', () => {
  const stringRequired = {
    type: String,
    required: true,
  };

  const stringOptional = {
    type: String,
    required: false,
  };

  const numberOptional = {
    type: Number,
    required: false,
  };

  const booleanRequired = {
    type: Boolean,
    required: true,
  };

  const FooComponent = {
    props: { foo: stringRequired },
  };

  const BarComponent = {
    props: { bar: numberOptional },
  };

  const FooBarComponent = {
    props: {
      foo: stringRequired,
      bar: numberOptional,
    },
  };

  const FooOptionalComponent = {
    props: {
      foo: stringOptional,
    },
  };

  const QuxComponent = {
    props: {
      foo: booleanRequired,
      qux: stringRequired,
    },
  };

  it('returns an empty object given no components', () => {
    expect(propsUnion([])).toEqual({});
  });

  it('merges non-overlapping props', () => {
    expect(propsUnion([FooComponent, BarComponent])).toEqual({
      ...FooComponent.props,
      ...BarComponent.props,
    });
  });

  it('merges overlapping props', () => {
    expect(propsUnion([FooComponent, BarComponent, FooBarComponent])).toEqual({
      ...FooComponent.props,
      ...BarComponent.props,
      ...FooBarComponent.props,
    });
  });

  it.each`
    components
    ${[FooComponent, FooOptionalComponent]}
    ${[FooOptionalComponent, FooComponent]}
  `('prefers required props over non-required props', ({ components }) => {
    expect(propsUnion(components)).toEqual(FooComponent.props);
  });

  it('throws if given props with conflicting types', () => {
    expect(() => propsUnion([FooComponent, QuxComponent])).toThrow(/incompatible prop types/);
  });

  it.each`
    components
    ${[{ props: ['foo', 'bar'] }]}
    ${[{ props: { foo: String, bar: Number } }]}
    ${[{ props: { foo: {}, bar: {} } }]}
  `('throw if given a non-verbose props object', ({ components }) => {
    expect(() => propsUnion(components)).toThrow(/expected verbose prop/);
  });
});
