import { render } from '~/lib/gfm';

describe('gfm', () => {
  const markdownToAST = async (markdown, skipRendering = []) => {
    let result;

    await render({
      markdown,
      skipRendering,
      renderer: (tree) => {
        result = tree;
      },
    });

    return result;
  };

  const expectInRoot = (result, ...nodes) => {
    expect(result).toEqual(
      expect.objectContaining({
        children: expect.arrayContaining(nodes),
      }),
    );
  };

  describe('render', () => {
    it('processes Commonmark and provides an ast to the renderer function', async () => {
      const result = await markdownToAST('This is text');

      expect(result.type).toBe('root');
    });

    it('transforms raw HTML into individual nodes in the AST', async () => {
      const result = await markdownToAST('<strong>This is bold text</strong>');

      expectInRoot(
        result,
        expect.objectContaining({
          children: expect.arrayContaining([
            expect.objectContaining({
              type: 'element',
              tagName: 'strong',
            }),
          ]),
        }),
      );
    });

    it('returns the result of executing the renderer function', async () => {
      const rendered = { value: 'rendered tree' };

      const result = await render({
        markdown: '<strong>This is bold text</strong>',
        renderer: () => {
          return rendered;
        },
      });

      expect(result).toEqual(rendered);
    });

    describe('when skipping the rendering of footnote reference and definition nodes', () => {
      it('transforms footnotes into footnotedefinition and footnotereference tags', async () => {
        const result = await markdownToAST(
          `footnote reference [^footnote]

[^footnote]: Footnote definition`,
          ['footnoteReference', 'footnoteDefinition'],
        );

        expectInRoot(
          result,
          expect.objectContaining({
            children: expect.arrayContaining([
              expect.objectContaining({
                type: 'element',
                tagName: 'footnotereference',
                properties: {
                  identifier: 'footnote',
                  label: 'footnote',
                },
              }),
            ]),
          }),
        );

        expectInRoot(
          result,
          expect.objectContaining({
            tagName: 'footnotedefinition',
            properties: {
              identifier: 'footnote',
              label: 'footnote',
            },
          }),
        );
      });
    });

    describe('when skipping the rendering of code blocks', () => {
      it('transforms code nodes into codeblock html tags', async () => {
        const result = await markdownToAST(
          `
\`\`\`javascript
console.log('Hola');
\`\`\`\
          `,
          ['code'],
        );

        expectInRoot(
          result,
          expect.objectContaining({
            tagName: 'codeblock',
            properties: {
              language: 'javascript',
            },
          }),
        );
      });
    });

    describe('when skipping the rendering of reference definitions', () => {
      it('transforms code nodes into codeblock html tags', async () => {
        const result = await markdownToAST(
          `
[gitlab][gitlab]

[gitlab]: https://gitlab.com "GitLab"
          `,
          ['definition'],
        );

        expectInRoot(
          result,
          expect.objectContaining({
            type: 'element',
            tagName: 'referencedefinition',
            properties: {
              identifier: 'gitlab',
              title: 'GitLab',
              url: 'https://gitlab.com',
            },
            children: [
              {
                type: 'text',
                value: '[gitlab]: https://gitlab.com "GitLab"',
              },
            ],
          }),
        );
      });
    });

    describe('when skipping the rendering of link and image references', () => {
      it('transforms linkReference and imageReference nodes into html tags', async () => {
        const result = await markdownToAST(
          `
[gitlab][gitlab] and ![GitLab Logo][gitlab-logo]

[gitlab]: https://gitlab.com "GitLab"
[gitlab-logo]: https://gitlab.com/gitlab-logo.png "GitLab Logo"
          `,
          ['linkReference', 'imageReference'],
        );

        expectInRoot(
          result,
          expect.objectContaining({
            tagName: 'p',
            children: expect.arrayContaining([
              expect.objectContaining({
                type: 'element',
                tagName: 'a',
                properties: expect.objectContaining({
                  href: 'https://gitlab.com',
                  isReference: 'true',
                  identifier: 'gitlab',
                  title: 'GitLab',
                }),
              }),
              expect.objectContaining({
                type: 'element',
                tagName: 'img',
                properties: expect.objectContaining({
                  src: 'https://gitlab.com/gitlab-logo.png',
                  isReference: 'true',
                  identifier: 'gitlab-logo',
                  title: 'GitLab Logo',
                  alt: 'GitLab Logo',
                }),
              }),
            ]),
          }),
        );
      });

      it('normalizes the urls extracted from the reference definitions', async () => {
        const result = await markdownToAST(
          `
[gitlab][gitlab] and ![GitLab Logo][gitlab]

[gitlab]: /url\\bar*baz
          `,
          ['linkReference', 'imageReference'],
        );

        expectInRoot(
          result,
          expect.objectContaining({
            tagName: 'p',
            children: expect.arrayContaining([
              expect.objectContaining({
                type: 'element',
                tagName: 'a',
                properties: expect.objectContaining({
                  href: '/url%5Cbar*baz',
                }),
              }),
              expect.objectContaining({
                type: 'element',
                tagName: 'img',
                properties: expect.objectContaining({
                  src: '/url%5Cbar*baz',
                }),
              }),
            ]),
          }),
        );
      });
    });
  });

  describe('when skipping the rendering of frontmatter types', () => {
    it.each`
      type      | input
      ${'yaml'} | ${'---\ntitle: page\n---'}
      ${'toml'} | ${'+++\ntitle: page\n+++'}
      ${'json'} | ${';;;\ntitle: page\n;;;'}
    `('transforms $type nodes into frontmatter html tags', async ({ input, type }) => {
      const result = await markdownToAST(input, [type]);

      expectInRoot(
        result,
        expect.objectContaining({
          type: 'element',
          tagName: 'frontmatter',
          properties: {
            language: type,
          },
          children: [
            {
              type: 'text',
              value: 'title: page',
            },
          ],
        }),
      );
    });
  });
});
