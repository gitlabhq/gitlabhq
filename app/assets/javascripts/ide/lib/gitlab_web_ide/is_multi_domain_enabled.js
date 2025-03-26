export const isMultiDomainEnabled = () =>
  gon?.dot_com === true && gon?.features?.webIdeMultiDomain === true;
