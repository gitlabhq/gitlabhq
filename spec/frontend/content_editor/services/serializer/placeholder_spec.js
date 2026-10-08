import { serialize, builders } from '../../serialization_utils';

const { paragraph, placeholder, bold, link } = builders;

describe('content_editor/services/serializer/placeholder', () => {
  it('serializes the placeholder syntax, not the value', () => {
    expect(
      serialize(paragraph('in ', placeholder({ placeholder: '%{project_name}', value: 'gitlab' }))),
    ).toBe('in %{project_name}');
  });

  it('serializes an unresolved placeholder', () => {
    expect(serialize(paragraph(placeholder({ placeholder: '%{foo}', value: null })))).toBe(
      '%{foo}',
    );
  });

  it('does not insert whitespace around a placeholder adjacent to text', () => {
    expect(
      serialize(
        paragraph('foo', placeholder({ placeholder: '%{project_name}', value: 'gitlab' }), 'bar'),
      ),
    ).toBe('foo%{project_name}bar');
  });

  it('serializes a placeholder inside marks', () => {
    expect(
      serialize(
        paragraph(
          bold('strong ', placeholder({ placeholder: '%{project_name}', value: 'gitlab' })),
        ),
      ),
    ).toBe('**strong %{project_name}**');
  });

  it('serializes a placeholder as link text', () => {
    expect(
      serialize(
        paragraph(
          link(
            { href: 'http://localhost', canonicalSrc: 'http://%{gitlab_server}' },
            placeholder({ placeholder: '%{gitlab_server}', value: 'localhost' }),
          ),
        ),
      ),
    ).toBe('[%{gitlab_server}](http://%{gitlab_server})');
  });
});
