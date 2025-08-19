import { addAriaLabels } from '~/behaviors/markdown/accessibility';

describe('addAriaLabels', () => {
  let container;

  beforeEach(() => {
    // Create a container for our test DOM
    container = document.createElement('div');
    document.body.appendChild(container);
  });

  afterEach(() => {
    // Clean up after each test
    document.body.removeChild(container);
  });

  it('should add aria-label to checkbox without existing aria-label', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
          Sample checkbox text
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    expect(checkbox.getAttribute('aria-label')).toBe('Check option: Sample checkbox text');
  });

  it('should skip checkbox that already has aria-label', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" aria-label="Custom label" />
          Sample checkbox text
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    expect(checkbox.getAttribute('aria-label')).toBe('Custom label');
  });

  it('should handle null or undefined checkboxes gracefully', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
          Valid checkbox
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');

    expect(() => {
      addAriaLabels([null, undefined, checkbox]);
    }).not.toThrow();

    expect(checkbox.getAttribute('aria-label')).toBe('Check option: Valid checkbox');
  });

  it('should remove nested ul elements when generating aria-label', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
          Main item text
          <ul>
            <li>Nested item 1</li>
            <li>Nested item 2</li>
          </ul>
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    // The aria-label should only contain the main text, not the nested items
    expect(checkbox.getAttribute('aria-label')).toBe('Check option: Main item text');
  });

  it('should handle complex nested content', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
          <strong>Bold text</strong> and <em>italic text</em>
          <ul>
            <li>Should be removed</li>
          </ul>
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    expect(checkbox.getAttribute('aria-label')).toBe('Check option: Bold text and italic text');
  });

  it('should truncate very long text content', () => {
    const longText = 'a'.repeat(150);
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
          ${longText}
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    const ariaLabel = checkbox.getAttribute('aria-label');
    expect(ariaLabel).toContain('Check option:');
    expect(ariaLabel.length).toBeLessThan(150); // Should be truncated
  });

  it('should handle empty text content', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    expect(checkbox.getAttribute('aria-label')).toBe('Check option: ');
  });

  it('should handle whitespace-only text content', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />


        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    expect(checkbox.getAttribute('aria-label')).toBe('Check option: ');
  });

  it('should process multiple checkboxes correctly', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
          First checkbox
        </li>
        <li>
          <input type="checkbox" />
          Second checkbox
        </li>
        <li>
          <input type="checkbox" aria-label="Already has label" />
          Third checkbox
        </li>
      </ul>
    `;

    const checkboxes = container.querySelectorAll('input[type="checkbox"]');
    addAriaLabels(Array.from(checkboxes));

    expect(checkboxes[0].getAttribute('aria-label')).toBe('Check option: First checkbox');
    expect(checkboxes[1].getAttribute('aria-label')).toBe('Check option: Second checkbox');
    expect(checkboxes[2].getAttribute('aria-label')).toBe('Already has label');
  });

  it('should handle checkboxes with mixed content types', () => {
    container.innerHTML = `
      <ul>
        <li>
          <input type="checkbox" />
          Text with <code>code</code> and <a href="#">links</a>
        </li>
      </ul>
    `;

    const checkbox = container.querySelector('input[type="checkbox"]');
    addAriaLabels([checkbox]);

    expect(checkbox.getAttribute('aria-label')).toBe('Check option: Text with code and links');
  });
});
