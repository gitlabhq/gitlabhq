import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { wrapNodes, isTextNode } from '~/code_navigation/utils/dom_utils';

describe('Code Navigation DOM Utils', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  describe('isTextNode', () => {
    it('returns true for text nodes', () => {
      const textNode = document.createTextNode('test text');
      expect(isTextNode(textNode)).toBe(true);
    });

    it('returns false for element nodes', () => {
      const elementNode = document.createElement('div');
      expect(isTextNode(elementNode)).toBe(false);
    });

    it('returns false for comment nodes', () => {
      const commentNode = document.createComment('test comment');
      expect(isTextNode(commentNode)).toBe(false);
    });

    it('returns false for document fragment nodes', () => {
      const fragmentNode = document.createDocumentFragment();
      expect(isTextNode(fragmentNode)).toBe(false);
    });
  });

  describe('wrapNodes', () => {
    beforeEach(() => {
      setHTMLFixture('<div id="container"></div>');
    });

    it('returns a NodeList of child nodes', () => {
      const result = wrapNodes('hello world', 'test-class');

      expect(result).toBeInstanceOf(NodeList);
      expect(result.length).toBeGreaterThan(0);
    });

    it('handles simple text without spaces', () => {
      const result = wrapNodes('hello', 'test-class');

      expect(result).toHaveLength(1);
      expect(result[0].textContent).toBe('hello');
    });

    it('creates spans for spaces in text', () => {
      const result = wrapNodes('hello world', 'test-class');

      expect(result).toHaveLength(3);

      // Should have: text, span(space), text
      expect(result[0].textContent).toBe('hello');
      expect(result[1].tagName).toBe('SPAN');
      expect(result[1].textContent).toBe(' ');
      expect(result[2].textContent).toBe('world');
    });

    it('creates spans for tabs in text', () => {
      const result = wrapNodes('hello\tworld', 'test-class');

      expect(result).toHaveLength(3);

      // Should have: text, span(tab), text
      expect(result[0].textContent).toBe('hello');
      expect(result[1].tagName).toBe('SPAN');
      expect(result[1].textContent).toBe('\t');
      expect(result[2].textContent).toBe('world');
    });

    it('handles mixed spaces and tabs', () => {
      const result = wrapNodes('a \t b', 'test-class');

      expect(result).toHaveLength(5);
      expect(result[0].textContent).toBe('a');
      expect(result[1].textContent).toBe(' ');
      expect(result[2].textContent).toBe('\t');
      expect(result[3].textContent).toBe(' ');
      expect(result[4].textContent).toBe('b');
    });

    it('handles empty text', () => {
      const result = wrapNodes('', 'test-class');

      expect(result).toHaveLength(0);
    });

    it('handles whitespace-only text', () => {
      const result = wrapNodes('   ', 'test-class');

      expect(result).toHaveLength(3);
      Array.from(result).forEach((node) => {
        expect(node.textContent).toBe(' ');
        expect(node.tagName).toBe('SPAN');
      });
    });

    it('handles multiple consecutive spaces', () => {
      const result = wrapNodes('a   b', 'test-class');

      expect(result).toHaveLength(5);
      expect(result[0].textContent).toBe('a');
      expect(result[1].textContent).toBe(' ');
      expect(result[2].textContent).toBe(' ');
      expect(result[3].textContent).toBe(' ');
      expect(result[4].textContent).toBe('b');
    });

    it('preserves newlines in text', () => {
      const result = wrapNodes('hello\nworld', 'test-class');

      expect(result).toHaveLength(1);
      expect(result[0].textContent).toBe('hello\nworld');
    });

    it('works without classList parameter', () => {
      const result = wrapNodes('test');

      expect(result).toHaveLength(1);
      expect(result[0].textContent).toBe('test');
    });

    it('works without dataset parameter', () => {
      const result = wrapNodes('test', 'test-class');

      expect(result).toHaveLength(1);
      expect(result[0].textContent).toBe('test');
    });

    it('escapes HTML entities to prevent injection', () => {
      const maliciousText = '<script>alert("xss")</script>';
      const result = wrapNodes(maliciousText, 'test-class');

      // The text should be escaped and not executed as HTML
      // Even though innerHTML parses entities back, they're now safe text content
      expect(result).toHaveLength(1);
      expect(result[0].textContent).toBe('<script>alert("xss")</script>');

      // Verify no actual script elements were created
      const scriptElements = Array.from(result).filter((node) => node.tagName === 'SCRIPT');
      expect(scriptElements).toHaveLength(0);
    });

    it('escapes HTML entities in text with spaces', () => {
      const maliciousText = '<img src=x onerror=alert(1)> test';
      const result = wrapNodes(maliciousText, 'test-class');

      // Should escape the HTML and still handle the space properly
      expect(result).toHaveLength(7);
      expect(result[0].textContent).toBe('<img');
      expect(result[1].textContent).toBe(' ');
      expect(result[2].textContent).toBe('src=x');
      expect(result[3].textContent).toBe(' ');
      expect(result[4].textContent).toBe('onerror=alert(1)>');
      expect(result[5].textContent).toBe(' ');
      expect(result[6].textContent).toBe('test');

      // Verify no actual img elements were created
      const imgElements = Array.from(result).filter((node) => node.tagName === 'IMG');
      expect(imgElements).toHaveLength(0);
    });

    describe('data attribute injection prevention', () => {
      it('escapes malicious data attributes that could be used for script gadgets', () => {
        const maliciousText =
          '<div data-dismissal-path="/api/v4/user/emails" data-method="POST">Click me</div>';
        const result = wrapNodes(maliciousText, 'test-class');

        // Verify the dangerous data attributes are escaped as text content
        const fullText = Array.from(result)
          .map((node) => node.textContent)
          .join('');
        expect(fullText).toBe(
          '<div data-dismissal-path="/api/v4/user/emails" data-method="POST">Click me</div>',
        );

        // Verify no actual div elements with data attributes were created
        const divElements = Array.from(result).filter((node) => node.tagName === 'DIV');
        expect(divElements).toHaveLength(0);
      });

      it('escapes form-related data attributes', () => {
        const maliciousText =
          '<button data-form-action="/admin/users" data-http-method="DELETE">Delete User</button>';
        const result = wrapNodes(maliciousText, 'test-class');

        // Verify the dangerous form attributes are escaped
        const fullText = Array.from(result)
          .map((node) => node.textContent)
          .join('');
        expect(fullText).toBe(
          '<button data-form-action="/admin/users" data-http-method="DELETE">Delete User</button>',
        );

        // Verify no actual button elements were created
        const buttonElements = Array.from(result).filter((node) => node.tagName === 'BUTTON');
        expect(buttonElements).toHaveLength(0);
      });

      it('escapes JavaScript hook classes that could be exploited', () => {
        const maliciousText =
          '<div class="js-email-form qa-add-email-button" data-endpoint="/emails">Add Email</div>';
        const result = wrapNodes(maliciousText, 'test-class');

        // Verify the dangerous classes and data attributes are escaped
        const fullText = Array.from(result)
          .map((node) => node.textContent)
          .join('');
        expect(fullText).toBe(
          '<div class="js-email-form qa-add-email-button" data-endpoint="/emails">Add Email</div>',
        );

        // Verify no elements with JavaScript hook classes were created
        const elementsWithJsClass = Array.from(result).filter(
          (node) =>
            node.classList &&
            (Array.from(node.classList).some((cls) => cls.startsWith('js-')) ||
              Array.from(node.classList).some((cls) => cls.startsWith('qa-'))),
        );
        expect(elementsWithJsClass).toHaveLength(0);
      });

      it('escapes complex nested HTML with multiple dangerous attributes', () => {
        const maliciousText =
          '<form data-remote="true" data-url="/api/v4/user/emails" data-method="post"><input name="email" value="attacker@evil.com"><button class="js-submit-btn" data-disable-with="Adding...">Submit</button></form>';
        const result = wrapNodes(maliciousText, 'test-class');

        // Verify the entire malicious payload is escaped as text
        const fullText = Array.from(result)
          .map((node) => node.textContent)
          .join('');
        expect(fullText).toBe(
          '<form data-remote="true" data-url="/api/v4/user/emails" data-method="post"><input name="email" value="attacker@evil.com"><button class="js-submit-btn" data-disable-with="Adding...">Submit</button></form>',
        );

        // Verify no actual form elements were created
        const formElements = Array.from(result).filter((node) =>
          ['FORM', 'INPUT', 'BUTTON'].includes(node.tagName),
        );
        expect(formElements).toHaveLength(0);
      });

      it('escapes data attributes with blob and snippet URLs', () => {
        const maliciousText =
          '<a data-action-path="/gitlab-org/gitlab/-/blob/master/config/routes.rb" data-redirect-url="/snippets/new">View File</a>';
        const result = wrapNodes(maliciousText, 'test-class');

        // Verify the dangerous URLs are escaped
        const fullText = Array.from(result)
          .map((node) => node.textContent)
          .join('');
        expect(fullText).toBe(
          '<a data-action-path="/gitlab-org/gitlab/-/blob/master/config/routes.rb" data-redirect-url="/snippets/new">View File</a>',
        );

        // Verify no actual anchor elements with data attributes were created
        const anchorElements = Array.from(result).filter((node) => node.tagName === 'A');
        expect(anchorElements).toHaveLength(0);
      });
    });
  });
});
