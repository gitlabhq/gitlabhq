import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import mockProjects from 'test_fixtures_static/projects.json';
import { trimText } from 'helpers/text_helper';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import HighlightedText from '~/vue_shared/components/highlighted_text.vue';
import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';

describe('ProjectListItem component', () => {
  let wrapper;

  const project = JSON.parse(JSON.stringify(mockProjects))[0];

  const createWrapper = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(ProjectListItem, {
      propsData: {
        project,
        selected: false,
        ...propsData,
      },
    });
  };

  const findProjectNamespace = () => wrapper.findByTestId('project-namespace');

  it.each([true, false])('renders a checkmark correctly when selected === "%s"', (selected) => {
    createWrapper({
      propsData: {
        selected,
      },
    });

    expect(wrapper.findByTestId('selected-icon').exists()).toBe(selected);
  });

  it(`emits a "clicked" event when the button is clicked`, () => {
    createWrapper();

    expect(wrapper.emitted('click')).toBeUndefined();
    wrapper.findComponent(GlButton).vm.$emit('click');

    expect(wrapper.emitted('click')).toHaveLength(1);
  });

  it(`renders the project avatar`, () => {
    createWrapper();
    const avatar = wrapper.findComponent(ProjectAvatar);

    expect(avatar.exists()).toBe(true);
    expect(avatar.props()).toMatchObject({
      projectId: project.id,
      projectAvatarUrl: '',
      projectName: project.name_with_namespace,
    });
  });

  it(`renders a simple namespace name with a trailing slash`, () => {
    createWrapper({
      propsData: {
        project: {
          ...project,
          name_with_namespace: 'a / b',
        },
      },
    });
    const renderedNamespace = trimText(findProjectNamespace().text());

    expect(renderedNamespace).toBe('a /');
  });

  it(`renders a properly truncated namespace with a trailing slash`, () => {
    createWrapper({
      propsData: {
        project: {
          ...project,
          name_with_namespace: 'a / b / c / d / e / f',
        },
      },
    });
    const renderedNamespace = trimText(findProjectNamespace().text());

    expect(renderedNamespace).toBe('a / ... / e /');
  });

  it(`renders a simple namespace name of a GraphQL project`, () => {
    createWrapper({
      propsData: {
        project: {
          ...project,
          name_with_namespace: undefined,
          nameWithNamespace: 'test',
        },
      },
    });
    const renderedNamespace = trimText(findProjectNamespace().text());

    expect(renderedNamespace).toBe('test /');
  });

  it(`renders the project name`, () => {
    createWrapper({
      propsData: {
        project: {
          ...project,
          name: 'my-test-project',
        },
      },
    });

    const highlightedText = wrapper.findComponent(HighlightedText);
    expect(highlightedText.props('text')).toBe('my-test-project');
  });

  it(`passes text and match to HighlightedText for rendering`, () => {
    createWrapper({
      propsData: {
        project: {
          ...project,
          name: 'my-test-project',
        },
        matcher: 'pro',
      },
    });

    const highlightedText = wrapper.findComponent(HighlightedText);
    expect(highlightedText.props('text')).toBe('my-test-project');
    expect(highlightedText.props('match')).toBe('pro');
  });

  it('passes malicious input to HighlightedText without executing it', () => {
    const alertSpy = jest.spyOn(window, 'alert');
    const maliciousName = "my-xss-pro<script>alert('XSS');</script>ject";
    const maliciousMatcher = "pro<script>alert('XSS');</script>";

    createWrapper({
      propsData: {
        project: { ...project, name: maliciousName },
        matcher: maliciousMatcher,
      },
    });

    const highlightedText = wrapper.findComponent(HighlightedText);
    expect(highlightedText.props('text')).toBe(maliciousName);
    expect(highlightedText.props('match')).toBe(maliciousMatcher);
    expect(alertSpy).not.toHaveBeenCalled();
  });
});
