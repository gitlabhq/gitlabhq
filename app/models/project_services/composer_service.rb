# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'digest'
require 'composer'

class ComposerService < Service
  prop_accessor :package_mode, :package_type, :export_branches, :branch_filters,
                :export_tags, :tag_filters, :custom_json

  validates :package_mode, :package_type, presence: true, if: :activated?

  validates_each :custom_json,
    if: :allow_custom_json_validation? do |record, attr, value|
      begin
        name_re = /([A-Za-z0-9&_-]+\/[A-Za-z0-9&_-]+)/

        if value.empty?
          error = 'must be specified'
        elsif (cjson = ActiveSupport::JSON.decode(value))
          if cjson.empty?
            error = 'must not be empty'
          elsif !cjson['name']
            error = 'must have a name key specified'
          elsif cjson['name'].empty?
            error = 'name key must not be empty'
          elsif cjson['name'] != (name_re.match(cjson['name']) || [])[0]
            error = 'name key must be formatted as "namespace/project"'
          elsif !cjson['description']
            error = 'must have a description key specified'
          elsif cjson['description'].empty?
            error = 'description key must not be empty'
          end
        end
        record.errors.add(attr, error) if error

      rescue
        record.errors.add(attr, 'must be a valid JSON string')
      end
    end

  after_save :process_project

  def allow_custom_json_validation?
    activated? && package_mode == 'advanced'
  end

  def title
    'Composer'
  end

  def description
    'List your project as a composer package'
  end

  def help
    out = 'This project will be publicly listed as a composer package,
but usage of private and internal repositories will still
require authentication. '
    if package_mode == 'default'
      out += 'The package is exported using the project\'s composer.json. '\
      'Additional settings are ignored.'
    elsif package_mode == 'project'
      out += 'The package is exported using the project\'s attributes '\
      'The following settings are applied.'
    elsif package_mode == 'advanced'
      out += 'The package is exported using the custom json specified '\
      'in the configuration.'
    end
    out
  end

  def to_param
    'composer'
  end

  def fields
    [
      { type: 'fieldset', legend: 'Packaging:', fields:
        [
          { type: 'select',
            name: 'package_mode',
            title: 'Package Mode',
            choices:
            [
              ['Built-in: parse composer.json (default)', 'default'],
              ['Project: generate from project attributes', 'attributes'],
              ['Advanced: use custom JSON', 'advanced']
            ],
            default_choice: 'default'
          },
          { type: 'select',
            name: 'package_type',
            title: 'Package Type',
            hint: 'Applicable only on project package mode.',
            choices:
            [
              ['AGL Module', 'agl-module'],
              ['AnnotateCms Component', 'annotatecms-component'],
              ['AnnotateCms Module', 'annotatecms-module'],
              ['AnnotateCms Service', 'annotatecms-service'],
              ['Asgard Module', 'asgard-module'],
              ['Asgard Theme', 'asgard-theme'],
              ['Bitrix Component', 'bitrix-component'],
              ['Bitrix Module', 'bitrix-module'],
              ['Bitrix Theme', 'bitrix-theme'],
              ['CakePHP 2+ Plugin', 'cakephp-plugin'],
              ['CCFramework Ship', 'ccframework-ship'],
              ['CCFramework Theme', 'ccframework-theme'],
              ['Chef Cookbook', 'chef-cookbook'],
              ['Chef Role', 'chef-role'],
              ['CodeIgniter Library', 'codeigniter-library'],
              ['CodeIgniter Module', 'codeigniter-module'],
              ['CodeIgniter Third Party', 'codeigniter-third-party'],
              ['Composer Library (default)', 'library'],
              ['Composer Meta Package', 'metapackage'],
              ['Composer Plugin', 'composer-plugin'],
              ['Composer Project', 'project'],
              ['Concrete5 Block', 'concrete5-block'],
              ['Concrete5 Package', 'concrete5-package'],
              ['Concrete5 Theme', 'concrete5-theme'],
              ['Concrete5 Update', 'concrete5-update'],
              ['Craft Plugin', 'craft-plugin'],
              ['Croogo Plugin', 'croogo-plugin'],
              ['Croogo Theme', 'croogo-theme'],
              ['DokuWiki Plugin', 'dokuwiki-plugin'],
              ['DokuWiki Template', 'dokuwiki-template'],
              ['Dolibarr Module', 'dolibarr-module'],
              ['Drupal Drush', 'drupal-drush'],
              ['Drupal Library', 'drupal-library'],
              ['Drupal Module', 'drupal-module'],
              ['Drupal Profile', 'drupal-profile'],
              ['Drupal Theme', 'drupal-theme'],
              ['Elgg Plugin', 'elgg-plugin'],
              ['FuelPHP v1.x Module', 'fuel-module'],
              ['FuelPHP v1.x Package', 'fuel-package'],
              ['FuelPHP v1.x Theme', 'fuel-theme'],
              ['FuelPHP v2.x Component', 'fuelphp-component'],
              ['Grav Plugin', 'grav-plugin'],
              ['Grav Theme', 'grav-theme'],
              ['Hurad Plugin', 'hurad-plugin'],
              ['Hurad Theme', 'hurad-theme'],
              ['Joomla Component', 'joomla-component'],
              ['Joomla Library', 'joomla-library'],
              ['Joomla Module', 'joomla-module'],
              ['Joomla Plugin', 'joomla-plugin'],
              ['Joomla Template', 'joomla-template'],
              ['Kirby Plugin', 'kirby-plugin'],
              ['Kohana Module', 'kohana-module'],
              ['Laravel Library', 'laravel-library'],
              ['Lithium Library', 'lithium-library'],
              ['Lithium Source', 'lithium-source'],
              ['Magento Library', 'magento-library'],
              ['Magento Skin', 'magento-skin'],
              ['Magento Theme', 'magento-theme'],
              ['Mako Package', 'mako-package'],
              ['MediaWiki Extension', 'mediawiki-extension'],
              ['MODULEWork Module', 'modulework-module'],
              ['MODX Evo Library', 'modxevo-lib'],
              ['MODX Evo Module', 'modxevo-module'],
              ['MODX Evo Plugin', 'modxevo-plugin'],
              ['MODX Evo Snippet', 'modxevo-snippet'],
              ['MODX Evo Template', 'modxevo-template'],
              ['Moodle Admin Report', 'moodle-admin_report'],
              ['Moodle Assign Feedback', 'moodle-assignfeedback'],
              ['Moodle Assign Submission', 'moodle-assignsubmission'],
              ['Moodle Assignment', 'moodle-assignment'],
              ['Moodle Auth', 'moodle-auth'],
              ['Moodle Availability', 'moodle-availability'],
              ['Moodle Block', 'moodle-block'],
              ['Moodle Calendar Type', 'moodle-calendartype'],
              ['Moodle Course Report', 'moodle-coursereport'],
              ['Moodle Data Field', 'moodle-datafield'],
              ['Moodle Data Preset', 'moodle-datapreset'],
              ['Moodle Editor', 'moodle-editor'],
              ['Moodle Enrol', 'moodle-enrol'],
              ['Moodle Filter', 'moodle-filter'],
              ['Moodle Format', 'moodle-format'],
              ['Moodle Grade Export', 'moodle-gradeexport'],
              ['Moodle Grade Import', 'moodle-gradeimport'],
              ['Moodle Grade Report', 'moodle-gradereport'],
              ['Moodle Grading Form', 'moodle-gradingform'],
              ['Moodle Local', 'moodle-local'],
              ['Moodle Message', 'moodle-message'],
              ['Moodle Mod', 'moodle-mod'],
              ['Moodle Plagiarism', 'moodle-plagiarism'],
              ['Moodle Portfolio', 'moodle-portfolio'],
              ['Moodle Profile Field', 'moodle-profilefield'],
              ['Moodle Question Behaviour', 'moodle-qbehaviour'],
              ['Moodle Question Format', 'moodle-qformat'],
              ['Moodle Question Type', 'moodle-qtype'],
              ['Moodle Quiz Access', 'moodle-quizaccess'],
              ['Moodle Quiz', 'moodle-quiz'],
              ['Moodle Report', 'moodle-report'],
              ['Moodle Repository', 'moodle-repository'],
              ['Moodle Scorm Report', 'moodle-scormreport'],
              ['Moodle Theme', 'moodle-theme'],
              ['Moodle Tool', 'moodle-tool'],
              ['Moodle Web Service', 'moodle-webservice'],
              ['Moodle Workshop Allocation', 'moodle-workshopallocation'],
              ['Moodle Workshop Evaluation', 'moodle-workshopeval'],
              ['Moodle Workshop Form', 'moodle-workshopform'],
              ['October Module', 'october-module'],
              ['October Plugin', 'october-plugin'],
              ['October Theme', 'october-theme'],
              ['OXID Module', 'oxid-module'],
              ['OXID Out', 'oxid-out'],
              ['OXID Theme', 'oxid-theme'],
              ['PhpBB Extension', 'phpbb-extension'],
              ['PhpBB Language', 'phpbb-language'],
              ['PhpBB Style', 'phpbb-style'],
              ['Pimcore Plugin', 'pimcore-plugin'],
              ['Piwik Plugin', 'piwik-plugin'],
              ['PPI Module', 'ppi-module'],
              ['Prestashop: Module', 'prestashop-module'],
              ['Prestashop: Theme', 'prestashop-theme'],
              ['Puppet Module', 'puppet-module'],
              ['REDAXO Addon', 'redaxo-addon'],
              ['Roundcube Plugin', 'roundcube-plugin'],
              ['Shopware Backend Plugin', 'shopware-backend-plugin'],
              ['Shopware Core Plugin', 'shopware-core-plugin'],
              ['Shopware Frontend Plugin', 'shopware-frontend-plugin'],
              ['Shopware Theme', 'shopware-theme'],
              ['SilverStripe Module', 'silverstripe-module'],
              ['SilverStripe Theme', 'silverstripe-theme'],
              ['SMF Module', 'smf-module'],
              ['SMF Theme', 'smf-theme'],
              ['Symfony1 Plugin', 'symfony1-plugin'],
              ['Tusk Asset', 'tusk-asset'],
              ['Tusk Command', 'tusk-command'],
              ['Tusk Task', 'tusk-task'],
              ['TYPO3 CMS Extension', 'typo3-cms-extension'],
              ['TYPO3 Flow Boilerplate', 'typo3-flow-boilerplate'],
              ['TYPO3 Flow Build', 'typo3-flow-build'],
              ['TYPO3 Flow Framework', 'typo3-flow-framework'],
              ['TYPO3 Flow Package', 'typo3-flow-package'],
              ['TYPO3 Flow Plugin', 'typo3-flow-plugin'],
              ['TYPO3 Flow Site', 'typo3-flow-site'],
              ['Wolf CMS Plugin', 'wolfcms-plugin'],
              ['WordPress Core', 'wordpress-core'],
              ['WordPress Must Use Plugin', 'wordpress-muplugin'],
              ['WordPress Plugin', 'wordpress-plugin'],
              ['WordPress Theme', 'wordpress-theme'],
              ['Zend Extra', 'zend-extra'],
              ['Zend Library', 'zend-library'],
              ['Zend Module', 'zend-module'],
              ['Zikula Module', 'zikula-module'],
              ['Zikula Theme', 'zikula-theme']
            ],
            default_choice: 'library'
          }
        ]
      },
      { type: 'fieldset', legend: 'Branches:', fields:
        [
          { type: 'checkbox',
            name: 'export_branches',
            title: 'Export',
          },
          { type: 'text',
            name: 'branch_filters',
            title: 'Filters',
            placeholder: 'branches you wish to export comma separated.',
            hint: 'Separate branches with commas. '\
                  'Leave blank to export all branches.'
          }
        ]
      },
      { type: 'fieldset', legend: 'Tags:', fields:
        [
          { type: 'checkbox',
            name: 'export_tags',
            title: 'Export'
          },
          { type: 'text',
            name: 'tag_filters',
            title: 'Filters',
            placeholder: 'tags you wish to export comma separated.',
            hint: 'Separate tags with commas. '\
                  'Leave blank to export all tags.'
          }
        ]
      },
      { type: 'fieldset', legend: 'Advanced:', fields:
        [
          { type: 'textarea',
            name: 'custom_json',
            title: 'Custom JSON',
            placeholder: 'custom json to use for exporting this package.'
          }
        ]
      }
    ]
  end

  # disable test button
  def can_test?
    false
  end

  def supported_events
    %w(push tag_push)
  end

  def execute(push_data)
    process_project
  end

  def process_project

    # do not process when service template
    return if template?

    # delete the project repository file since it will be regenerated.
    File.delete(repo_path) if File.exists?(repo_path)

    if activated?
      # process packages for all tags
      project.repository.tags.each do |tag|
        process_commit(tag)
      end

      # process packages for all branches
      project.repository.branches.each do |branch|
        process_commit(branch)
      end

      # write the repository json file.
      repository.write
    end

    # update the root json file to include/exlude this project.
    update_root_file

  end

  def process_commit(ref)
    if activated? && ref_exported?(ref)
      package = ref_package(ref)
      repository.add_package(package)
    end
  rescue Exception => e
    # These errors are non-critical and have an impact on the exported
    # packages. These errors can be ignored and are logged for troubleshooting.
    log(e.message)
  end

  def update_root_file
    root_json = Composer::Json::JsonFile.new(root_path)
    root = root_json.read
    key = "p/#{repo_filename}"
    includes = root['includes'] || {}

    if activated?
      includes[key] ||= {}
      includes[key]['sha1'] = Digest::SHA1.file(repo_path).hexdigest
      includes = includes.sort_by{|k,v| k}.to_h
    else
      includes.delete(key)
    end

    root_json.write({ packages: [], includes: includes })
  rescue Exception => e
    # These errors are critical indicating that we can not process
    # the root json file. Log and raise
    log(e.message)
    raise e
  end

  private

  def ref_package(ref)
    case package_mode
    when 'default'
      loader = Composer::Package::Loader::ProjectRootLoader.new
      loader.load(project, ref)
    when 'attributes'
      loader = Composer::Package::Loader::ProjectAttributesLoader.new
      loader.load(project, ref, package_type)
    when 'advanced'
      loader = Composer::Package::Loader::ProjectLoader.new
      loader.load(project, ref, ActiveSupport::JSON.decode(custom_json))
    end
  end

  def repository
    @repository ||= Composer::Repository::ProjectRepository.new(
      Composer::Json::JsonFile.new(repo_path)
    )
  end

  def ref_exported?(ref)
    if ref.instance_of?(Gitlab::Git::Branch)
      branch_exported?(ref)
    elsif ref.instance_of?(Gitlab::Git::Tag)
      tag_exported?(ref)
    else
      false
    end
  end

  def branch_exported?(branch)
    if branch_filters
      filters = branch_filters.strip! || branch_filters
      filters = filters.gsub(' ', '').split(',')
    else
      filters = []
    end
    if filters.empty?
      export_branches == '1'
    else
      export_branches == '1' && filters.include?(branch.name)
    end
  end

  def tag_exported?(tag)
    if tag_filters
      filters = tag_filters.strip! || tag_filters
      filters = filters.gsub(' ', '').split(',')
    else
      filters = []
    end
    if filters.empty?
      export_tags == '1'
    else
      export_tags == '1' && filters.include?(tag.name)
    end
  end

  def output_dir
    Rails.public_path
  end

  def provider_dir
    File.join(output_dir, '/p');
  end

  def root_filename
    'packages.json'
  end

  def root_path
    File.join(output_dir, root_filename)
  end

  def repo_filename
    "project-#{project.id}.json"
  end

  def repo_path
    File.join(provider_dir, repo_filename)
  end

  def log(message)
    Gitlab::AppLogger.error("ComposerService: #{message}")
  end
end
