import OrganizationUsersTokenSelect from './organization_users_token_select.vue';

export default {
  component: OrganizationUsersTokenSelect,
  title: 'organizations/admin/components/organization_users_token_select',
  provide: {
    searchUrl: '/-/autocomplete/users.json',
  },
};

const defaultProps = {
  ariaLabelledby: 'organization-users-token-select-label',
  inputId: 'organization-users-token-select',
  isValid: true,
  selectedTokens: [],
};

const Template = (args) => ({
  components: { OrganizationUsersTokenSelect },
  props: Object.keys(args),
  template: `
    <div>
      <label :id="ariaLabelledby">Search for users to invite</label>
      <organization-users-token-select
        :aria-labelledby="ariaLabelledby"
        :input-id="inputId"
        :is-valid="isValid"
        :selected-tokens="selectedTokens"
      />
    </div>
  `,
});

export const Default = Template.bind({});
Default.args = defaultProps;

export const WithSelectedTokens = Template.bind({});
WithSelectedTokens.args = {
  ...defaultProps,
  selectedTokens: [
    { id: 1, name: 'Administrator', username: 'root' },
    { id: 2, name: 'Jane Doe', username: 'jane' },
  ],
};

export const Invalid = Template.bind({});
Invalid.args = {
  ...defaultProps,
  isValid: false,
};

export const InviteCapReached = Template.bind({});
InviteCapReached.args = {
  ...defaultProps,
  selectedTokens: Array.from({ length: 20 }, (_, i) => ({
    id: i + 1,
    name: `User ${i + 1}`,
    username: `user${i + 1}`,
  })),
};
