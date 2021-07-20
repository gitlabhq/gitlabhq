import ProjectAvatar from './project_avatar.vue';

export default {
  component: ProjectAvatar,
  title: 'vue_shared/components/project_avatar',
};

const Template = (args, { argTypes }) => ({
  components: { ProjectAvatar },
  props: Object.keys(argTypes),
  template: '<project-avatar v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  projectAvatarUrl:
    'https://gitlab.com/uploads/-/system/project/avatar/278964/logo-extra-whitespace.png?width=64',
  projectName: 'GitLab',
};

export const FallbackAvatar = Template.bind({});
FallbackAvatar.args = {
  projectName: 'GitLab',
};

export const EmptyAltTag = Template.bind({});
EmptyAltTag.args = {
  ...Default.args,
  alt: '',
};
