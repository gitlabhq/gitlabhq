import { FILE_EXTENSION_MAPPING_HLJS } from '~/repository/constants';

describe('FILE_EXTENSION_MAPPING_HLJS', () => {
  it('maps .tf extension to hcl language for Terraform files', () => {
    expect(FILE_EXTENSION_MAPPING_HLJS['.tf']).toBe('hcl');
  });

  it('maps .tfvars extension to hcl language for Terraform variable files', () => {
    expect(FILE_EXTENSION_MAPPING_HLJS['.tfvars']).toBe('hcl');
  });

  it('includes Terraform file extensions in the mapping', () => {
    const hasTerraformExtensions = ['.tf', '.tfvars'].every((ext) =>
      Object.keys(FILE_EXTENSION_MAPPING_HLJS).includes(ext),
    );
    expect(hasTerraformExtensions).toBe(true);
  });
});
