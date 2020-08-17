import adapter from 'axios/lib/adapters/xhr';
import axios from '~/lib/utils/axios_utils';

// We're removing our default axios adapter because this is handled by our mock server now
axios.defaults.adapter = adapter;
