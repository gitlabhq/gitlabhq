# frozen_string_literal: true

RSpec.describe ActionDispatch::DrawAll do
  let(:routes_dir) { File.expand_path("../fixtures/config/routes", __dir__) }
  let(:routes_ee_dir) { File.expand_path("../fixtures/config/routes_ee", __dir__) }
  let(:route_set) { ActionDispatch::Routing::RouteSet.new }

  def mock_rails_config(routes_key, route_paths)
    paths_object = instance_double(
      Rails::Paths::Path,
      paths: route_paths.map { |path| Pathname.new(path) }
    )

    paths_hash = instance_double(Rails::Paths::Root)
    allow(paths_hash).to receive(:[]).with(routes_key).and_return(paths_object)

    config = instance_double(
      Rails::Engine::Configuration,
      paths: paths_hash
    )

    allow(Rails).to receive(:application).and_return(
      instance_double(Rails::Application, config: config)
    )
  end

  describe '#draw_all' do
    context 'when we configure one routes_dir' do
      before do
        mock_rails_config('config/routes', [routes_dir])
      end

      it 'draws routes from matching files' do
        route_set.draw do
          draw_all :api
        end

        expect(route_set.routes.size).to be > 0
        route_paths = route_set.routes.map { |r| r.path.spec.to_s }
        expect(route_paths).to include('/api/status(.:format)')
      end

      it 'draws multiple route files' do
        route_set.draw do
          draw_all :api
          draw_all :admin
        end

        route_paths = route_set.routes.map { |r| r.path.spec.to_s }
        expect(route_paths).to include('/api/status(.:format)')
        expect(route_paths).to include('/admin/dashboard(.:format)')
      end

      it 'raises RoutesNotFound when route file does not exist' do
        expect do
          route_set.draw do
            draw_all :nonexistent
          end
        end.to raise_error(ActionDispatch::DrawAll::RoutesNotFound)
      end

      it 'raises RoutesNotFound when some files exist and others do not' do
        expect do
          route_set.draw do
            draw_all :api
            draw_all :missing
          end
        end.to raise_error(ActionDispatch::DrawAll::RoutesNotFound)
      end
    end

    context 'when we configure multiple routes_dir' do
      before do
        mock_rails_config('config/routes', [routes_dir, routes_ee_dir])
      end

      it 'draws routes from matching files in all directories' do
        route_set.draw do
          draw_all :api
        end

        route_paths = route_set.routes.map { |r| r.path.spec.to_s }
        # Both api.rb files should be loaded - one from routes_dir and one from routes_ee_dir
        expect(route_paths).to include('/api/status(.:format)')
        expect(route_paths).to include('/api/premium(.:format)')
      end

      it 'draws routes from all matching files when multiple exist' do
        route_set.draw do
          draw_all :api
        end

        # Should have routes from both directories
        route_paths = route_set.routes.map { |r| r.path.spec.to_s }
        expect(route_paths.count { |p| p.start_with?('/api/') }).to eq(2)
      end

      it 'draws routes from files that exist in only one directory' do
        route_set.draw do
          draw_all :admin
        end

        # admin.rb only exists in routes_dir, not in routes_ee_dir
        route_paths = route_set.routes.map { |r| r.path.spec.to_s }
        expect(route_paths).to include('/admin/dashboard(.:format)')
      end

      it 'raises RoutesNotFound when route file does not exist in any directory' do
        expect do
          route_set.draw do
            draw_all :nonexistent
          end
        end.to raise_error(ActionDispatch::DrawAll::RoutesNotFound)
      end

      it 'raises RoutesNotFound when some files exist and others do not' do
        expect do
          route_set.draw do
            draw_all :api
            draw_all :missing
          end
        end.to raise_error(ActionDispatch::DrawAll::RoutesNotFound)
      end
    end
  end

  describe 'version' do
    it 'has a version number' do
      expect(ActionDispatch::DrawAll::VERSION).not_to be_nil
    end
  end
end
