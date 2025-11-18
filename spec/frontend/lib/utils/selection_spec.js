import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { querySelectionClosest } from '~/lib/utils/selection';

describe('querySelectionClosest', () => {
  const setSelection = (range) => {
    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
  };

  beforeEach(() => {
    resetHTMLFixture();
  });

  afterEach(() => {
    window.getSelection().removeAllRanges();
  });

  it('returns null when there is no selection', () => {
    const result = querySelectionClosest('.test');
    expect(result).toBeNull();
  });

  it('finds closest parent matching selector from text node', () => {
    setHTMLFixture(`
      <div class="container">
        <p class="paragraph">
          <span id="target">Some text here</span>
        </p>
      </div>
    `);

    const textNode = document.getElementById('target').firstChild;
    const range = document.createRange();
    range.selectNodeContents(textNode);

    setSelection(range);

    const result = querySelectionClosest('.paragraph');
    expect(result).toBe(document.querySelector('.paragraph'));
  });

  it('finds closest parent matching selector from element node', () => {
    setHTMLFixture(`
      <div class="container">
        <p class="paragraph">
          <span id="target">Text</span>
        </p>
      </div>
    `);

    const span = document.getElementById('target');
    const range = document.createRange();
    range.selectNode(span);

    setSelection(range);

    const result = querySelectionClosest('.container');
    expect(result).toBe(document.querySelector('.container'));
  });

  it('returns null when no matching parent exists', () => {
    setHTMLFixture(`
      <div class="container">
        <span id="target">Text</span>
      </div>
    `);

    const textNode = document.getElementById('target').firstChild;
    const range = document.createRange();
    range.selectNodeContents(textNode);

    setSelection(range);

    const result = querySelectionClosest('.non-existent');
    expect(result).toBeNull();
  });

  it('can match the element itself', () => {
    setHTMLFixture(`
      <div class="container">
        <span class="highlight" id="target">Text</span>
      </div>
    `);

    const span = document.getElementById('target');
    const textNode = span.firstChild;
    const range = document.createRange();
    range.selectNodeContents(textNode);

    setSelection(range);

    const result = querySelectionClosest('.highlight');
    expect(result).toBe(span);
  });
});
