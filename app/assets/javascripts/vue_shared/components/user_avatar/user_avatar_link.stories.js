import UserAvatarLink from './user_avatar_link.vue';

export default {
  component: UserAvatarLink,
  title: 'vue_shared/user_avatar/user_avatar_link',
};

const Template = (args, { argTypes }) => ({
  components: { UserAvatarLink },
  props: Object.keys(argTypes),
  template: '<UserAvatarLink v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  lazy: false,
  linkHref: '/root',
  imgSrc: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  imgAlt: 'Administrator',
  imgCssClasses: '',
  imgCssWrapperClasses: '',
  imgSize: 32,
  tooltipText: 'Administrator',
  tooltipPlacement: 'top',
  popoverUserId: '',
  popoverUsername: '',
  username: '',
};

export const WithUsername = Template.bind({});
WithUsername.args = {
  ...Default.args,
  username: 'root',
};

export const WithPopover = Template.bind({});
WithPopover.args = {
  ...Default.args,
  popoverUserId: 'gid://gitlab/User/1',
  popoverUsername: 'root',
};
