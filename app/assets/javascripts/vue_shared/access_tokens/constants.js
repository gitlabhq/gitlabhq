export const ACCESS_USER_ENUM = 'USER';
export const ACCESS_INSTANCE_ENUM = 'INSTANCE';
export const ACCESS_NAMESPACE_ENUMS = ['GROUP', 'PROJECT'];
export const ACCESS_SCOPES = [
  { key: 'namespace', boundaries: ACCESS_NAMESPACE_ENUMS },
  { key: 'user', boundaries: [ACCESS_USER_ENUM] },
  { key: 'instance', boundaries: [ACCESS_INSTANCE_ENUM] },
];

export const ACCESS_SCOPE_KEYS = ACCESS_SCOPES.map(({ key }) => key);
