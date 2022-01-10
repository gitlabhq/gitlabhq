import { diff } from 'jest-diff';

describe('custom matcher toHaveTrackingAttributes', () => {
  const createElementWithAttrs = (attributes) => {
    const el = document.createElement('div');

    Object.entries(attributes).forEach(([key, value]) => {
      el.setAttribute(key, value);
    });

    return el;
  };

  it('blows up if actual is not an element', () => {
    expect(() => {
      expect({}).toHaveTrackingAttributes({});
    }).toThrow('The received value must be an Element.');
  });

  it('blows up if expected is not an object', () => {
    expect(() => {
      expect(createElementWithAttrs({})).toHaveTrackingAttributes('foo');
    }).toThrow('The matching object must be an object.');
  });

  it('prints diff when fails', () => {
    const expectedDiff = diff({ label: 'foo' }, { label: 'a' });
    expect(() => {
      expect(createElementWithAttrs({ 'data-track-label': 'foo' })).toHaveTrackingAttributes({
        label: 'a',
      });
    }).toThrow(
      `Expected the element's tracking attributes to match the given object. Diff:\n${expectedDiff}\n`,
    );
  });

  describe('positive assertions', () => {
    it.each`
      attrs                                                       | expected
      ${{ 'data-track-label': 'foo' }}                            | ${{ label: 'foo' }}
      ${{ 'data-track-label': 'foo' }}                            | ${{}}
      ${{ 'data-track-label': 'foo', label: 'bar' }}              | ${{ label: 'foo' }}
      ${{ 'data-track-label': 'foo', 'data-track-extra': '123' }} | ${{ label: 'foo', extra: '123' }}
      ${{ 'data-track-label': 'foo', 'data-track-extra': '123' }} | ${{ extra: '123' }}
      ${{ label: 'foo', extra: '123', id: '7' }}                  | ${{}}
    `('$expected matches element with attrs $attrs', ({ attrs, expected }) => {
      expect(createElementWithAttrs(attrs)).toHaveTrackingAttributes(expected);
    });
  });

  describe('negative assertions', () => {
    it.each`
      attrs                                                       | expected
      ${{}}                                                       | ${{ label: 'foo' }}
      ${{ label: 'foo' }}                                         | ${{ label: 'foo' }}
      ${{ 'data-track-label': 'bar', label: 'foo' }}              | ${{ label: 'foo' }}
      ${{ 'data-track-label': 'foo' }}                            | ${{ extra: '123' }}
      ${{ 'data-track-label': 'foo', 'data-track-extra': '123' }} | ${{ label: 'foo', extra: '456' }}
      ${{ 'data-track-label': 'foo', 'data-track-extra': '123' }} | ${{ label: 'foo', extra: '123', action: 'click' }}
      ${{ label: 'foo', extra: '123', id: '7' }}                  | ${{ id: '7' }}
    `('$expected does not match element with attrs $attrs', ({ attrs, expected }) => {
      expect(createElementWithAttrs(attrs)).not.toHaveTrackingAttributes(expected);
    });
  });
});
