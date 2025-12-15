import { initSharedAccessTokenApp, initTokensApp } from '~/access_tokens';
import { initPersonalAccessTokenApp } from '~/personal_access_tokens';

// Legacy Token User PAT page, uses REST
initSharedAccessTokenApp();

// Granular Token User PAT page, uses GraphQL
initPersonalAccessTokenApp();
initTokensApp();
